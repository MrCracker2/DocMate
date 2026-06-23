import Foundation

struct ParsedDates {
    let issueDate: Date?
    let expiryDate: Date?
}

/// Extracts issue / expiry dates from OCR'd document text.
///
/// Design notes (why this is more robust than a hand-rolled regex):
/// - Date *detection* is delegated to `NSDataDetector`, Apple's locale-aware
///   data detector. It understands numeric, slash, dotted, ISO, ordinal
///   ("5th"), and text-month ("Jan 5, 2026" / "5 January 2026") dates, and
///   resolves ambiguous day/month order using the user's locale.
/// - Keyword matching uses **word boundaries** (`\bexp\b`) so labels like
///   "exp"/"expiry" no longer false-match inside words such as "experience",
///   "export" or "expense".
/// - A detected date is only reported as an expiry when it is anchored to an
///   expiry keyword (or a from→to range). There is no "grab any date" fallback.
/// - Detected dates are sanity-bounded to a plausible calendar window so OCR
///   misreads (year 0207, 9999, …) are discarded.
final class DateParser: Sendable {

    // MARK: - Keywords

    private let expiryKeywords = [
        "expiry", "expiry date", "expires", "expires on", "expires by",
        "expired", "expiration", "expiration date", "exp", "exp date",
        "valid until", "valid till", "valid thru", "valid through",
        "valid upto", "valid up to", "use by", "best before",
        "maturity", "maturity date", "date of maturity", "matures on",
        "renewal", "renewal date", "renew by", "due date", "good until",
        "good thru", "lapse date"
    ]

    private let issueKeywords = [
        "issue date", "issued on", "issued", "date of issue", "start date",
        "valid from", "effective", "commencement", "commencing", "doi"
    ]

    /// Words that mark a date *range* as a validity period (so its later date is
    /// an expiry). Used to gate the from→to branch — without one of these, a
    /// bare range like a billing period is NOT treated as an expiry.
    private let validityKeywords = [
        "valid", "validity", "valid from", "valid until", "valid till",
        "valid thru", "valid through", "policy period", "period of insurance",
        "coverage", "cover period", "term", "effective"
    ]

    /// How far (in characters) before a date we look for an anchoring keyword.
    /// Covers "Expiry Date: 01/01/2027" and label-on-previous-line layouts.
    private let contextWindow = 80

    private struct Candidate {
        let date: Date
        var score: Int
    }

    // MARK: - Main Entry

    /// Convenience entry for a single block of text.
    nonisolated func parse(from text: String) -> ParsedDates {
        parse(pages: [text])
    }

    /// Parses each page **independently** and keeps the highest-scoring
    /// candidate across pages. Parsing per page (rather than one concatenated
    /// blob) prevents a keyword at the bottom of one page from being matched to
    /// a date at the top of the next.
    nonisolated func parse(pages: [String]) -> ParsedDates {
        var bestExpiry: Candidate?
        var bestIssue: Candidate?

        for page in pages {
            let result = candidates(in: page)
            if let e = result.expiry, bestExpiry == nil || e.score > bestExpiry!.score {
                bestExpiry = e
            }
            if let i = result.issue, bestIssue == nil || i.score > bestIssue!.score {
                bestIssue = i
            }
        }

        return ParsedDates(issueDate: bestIssue?.date, expiryDate: bestExpiry?.date)
    }

    // MARK: - Per-page Candidate Extraction

    nonisolated private func candidates(in text: String) -> (expiry: Candidate?, issue: Candidate?) {
        let matches = detectDates(in: text)
        guard !matches.isEmpty else { return (nil, nil) }

        var expiryCandidate: Candidate?
        var issueCandidate: Candidate?

        func considerExpiry(_ date: Date, score: Int) {
            if expiryCandidate == nil || score > expiryCandidate!.score {
                expiryCandidate = Candidate(date: date, score: score)
            }
        }
        func considerIssue(_ date: Date, score: Int) {
            if issueCandidate == nil || score > issueCandidate!.score {
                issueCandidate = Candidate(date: date, score: score)
            }
        }

        let today = Date()

        // MARK: from → to range (e.g. "Valid 01/2024 to 12/2026")
        // If two dates sit within the same window joined by "to"/"-" AND the
        // surrounding text marks it as a validity period, treat the later date
        // as expiry and the earlier as issue. The validity gate prevents bare
        // ranges (e.g. a bill's "billing period 01/01 to 31/01") from being
        // mistaken for an expiry.
        if matches.count >= 2 {
            for i in 0..<(matches.count - 1) {
                let a = matches[i]
                let b = matches[i + 1]
                let between = substring(of: text, from: a.range.upperBound, to: b.range.lowerBound)
                let rangeContext = precedingContext(of: text, before: a.range.lowerBound) + between
                if matchesKeyword(["to", "-", "–", "—", "through", "thru", "until", "till"], in: between, wholeWord: true),
                   matchesKeyword(validityKeywords, in: rangeContext) {
                    let pair = [a.date, b.date].sorted()
                    considerIssue(pair[0], score: 500)
                    considerExpiry(pair[1], score: 500)
                }
            }
        }

        // MARK: keyword-anchored classification
        for match in matches {
            let context = precedingContext(of: text, before: match.range.lowerBound)

            if matchesKeyword(expiryKeywords, in: context) {
                var score = 200
                if match.date > today { score += 20 } // an expiry is usually in the future
                considerExpiry(match.date, score: score)
            }

            if matchesKeyword(issueKeywords, in: context) {
                var score = 150
                if match.date <= today { score += 20 } // an issue date is usually in the past
                considerIssue(match.date, score: score)
            }
        }

        return (expiryCandidate, issueCandidate)
    }

    // MARK: - Date Detection (NSDataDetector + sanity bounds)

    private struct DetectedDate {
        let date: Date
        let range: Range<String.Index>
    }

    nonisolated private func detectDates(in text: String) -> [DetectedDate] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return []
        }

        let calendar = Calendar(identifier: .gregorian)
        let currentYear = calendar.component(.year, from: Date())
        let lowerYear = currentYear - 30   // tolerate older issue dates
        let upperYear = currentYear + 50   // tolerate long-dated expiries

        var results: [DetectedDate] = []
        let nsRange = NSRange(text.startIndex..., in: text)

        detector.enumerateMatches(in: text, range: nsRange) { match, _, _ in
            guard let match, let date = match.date,
                  let range = Range(match.range, in: text) else { return }

            let year = calendar.component(.year, from: date)
            guard year >= lowerYear, year <= upperYear else { return }

            results.append(DetectedDate(date: date, range: range))
        }

        return results
    }

    // MARK: - Keyword Matching (word-boundary aware)

    /// Returns true if any keyword appears in `text` as a whole word/phrase.
    nonisolated private func matchesKeyword(_ keywords: [String], in text: String, wholeWord: Bool = false) -> Bool {
        guard !text.isEmpty else { return false }
        let lower = text.lowercased()

        for keyword in keywords {
            let escaped = NSRegularExpression.escapedPattern(for: keyword.lowercased())
            // \b only works around word characters; for purely symbolic keywords
            // (e.g. "-") fall back to a plain contains check.
            let pattern: String
            if keyword.range(of: "[A-Za-z0-9]", options: .regularExpression) != nil {
                pattern = "\\b\(escaped)\\b"
            } else {
                if lower.contains(keyword.lowercased()) { return true }
                continue
            }

            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(lower.startIndex..., in: lower)
                if regex.firstMatch(in: lower, range: range) != nil {
                    return true
                }
            }
            _ = wholeWord
        }
        return false
    }

    // MARK: - Context Helpers

    /// The text immediately preceding `index`, capped at `contextWindow` chars.
    nonisolated private func precedingContext(of text: String, before index: String.Index) -> String {
        let start = text.index(index, offsetBy: -contextWindow, limitedBy: text.startIndex) ?? text.startIndex
        return String(text[start..<index])
    }

    nonisolated private func substring(of text: String, from: String.Index, to: String.Index) -> String {
        guard from <= to else { return "" }
        return String(text[from..<to])
    }
}
