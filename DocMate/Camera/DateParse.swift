import Foundation

struct ParsedDates {
    let issueDate: Date?
    let expiryDate: Date?
}

final class DateParser {

    // MARK: - Keywords
    private let expiryKeywords = [
        "expiry", "expires", "exp", "expiry date", "valid until",
        "valid till", "use by", "maturity", "renewal", "due date"
    ]

    private let issueKeywords = [
        "issue date", "issued on", "start date", "from", "commencement"
    ]

    // MARK: - Main Entry
    func parse(from text: String) -> ParsedDates {
        let lines = text.components(separatedBy: .newlines)
        let today = Date()

        struct Candidate {
            let raw: String
            let date: Date
            var score: Int
        }

        var expiryCandidate: Candidate?
        var issueCandidate: Candidate?

        // MARK: - Process each line with context
        for (i, line) in lines.enumerated() {

            let lower = line.lowercased()
            let next = (i + 1 < lines.count) ? lines[i + 1].lowercased() : ""
            let context = lower + " " + next

            let dateStrings = extractAllDateStrings(from: context)

            var parsedDates: [(String, Date)] = []

            for raw in dateStrings {
                if let d = parseDate(from: raw) {
                    parsedDates.append((raw, d))
                }
            }

            if parsedDates.isEmpty { continue }

            // MARK: - RANGE CASE (from → to)
            if parsedDates.count >= 2,
               context.contains(" to ") || context.contains("from") {

                let sorted = parsedDates.sorted { $0.1 < $1.1 }

                issueCandidate = Candidate(raw: sorted[0].0, date: sorted[0].1, score: 500)
                expiryCandidate = Candidate(raw: sorted[1].0, date: sorted[1].1, score: 500)
                continue
            }

            // MARK: - Expiry Detection
            if expiryKeywords.contains(where: { context.contains($0) }) {
                for (raw, d) in parsedDates {
                    var score = 200

                    if d > today { score += 20 }  // future boost

                    if expiryCandidate == nil || score > expiryCandidate!.score {
                        expiryCandidate = Candidate(raw: raw, date: d, score: score)
                    }
                }
            }

            // MARK: - Issue Detection
            if issueKeywords.contains(where: { context.contains($0) }) {
                for (raw, d) in parsedDates {
                    let score = 150

                    if issueCandidate == nil || score > issueCandidate!.score {
                        issueCandidate = Candidate(raw: raw, date: d, score: score)
                    }
                }
            }
        }

        // MARK: - Fallback Expiry (latest date)
        if expiryCandidate == nil {
            var all: [(String, Date)] = []

            for line in lines {
                for raw in extractAllDateStrings(from: line) {
                    if let d = parseDate(from: raw) {
                        all.append((raw, d))
                    }
                }
            }

            if let latest = all.sorted(by: { $0.1 < $1.1 }).last {
                expiryCandidate = Candidate(raw: latest.0, date: latest.1, score: 10)
            }
        }

        // MARK: - Fallback Issue (earliest date)
        if issueCandidate == nil {
            var all: [(String, Date)] = []

            for line in lines {
                for raw in extractAllDateStrings(from: line) {
                    if let d = parseDate(from: raw) {
                        all.append((raw, d))
                    }
                }
            }

            if let earliest = all.sorted(by: { $0.1 < $1.1 }).first {
                issueCandidate = Candidate(raw: earliest.0, date: earliest.1, score: 10)
            }
        }

        return ParsedDates(
            issueDate: issueCandidate?.date,
            expiryDate: expiryCandidate?.date
        )
    }

    // MARK: - Extract ALL date strings (Regex)
    private func extractAllDateStrings(from text: String) -> [String] {
        let patterns = [
            #"(\b\d{1,2}[-/.]\d{1,2}[-/.]\d{2,4}\b)"#,
            #"(\b\d{4}[-/]\d{1,2}[-/]\d{1,2}\b)"#,
            #"(\b\d{1,2}\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{2,4}\b)"#
        ]

        var results: [String] = []

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))

                for match in matches {
                    if let range = Range(match.range, in: text) {
                        results.append(String(text[range]))
                    }
                }
            }
        }

        return results
    }

    // MARK: - Parse Date
    private func parseDate(from raw: String) -> Date? {
        let formats = [
            "dd/MM/yyyy", "dd-MM-yyyy", "dd.MM.yyyy",
            "dd/MM/yy", "dd-MM-yy",
            "yyyy-MM-dd", "yyyy/MM/dd",
            "dd MMM yyyy", "d MMM yyyy"
        ]

        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")

        for format in formats {
            df.dateFormat = format
            if let date = df.date(from: raw) {
                return date
            }
        }

        return nil
    }
}
