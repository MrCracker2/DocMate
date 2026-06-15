//
//  BillParser.swift
//  DocMate
//
//  Created by Shashwat kumar on 27/04/26.
//

import Foundation

/// Heuristic parser that turns a raw Gmail bill/invoice email into an `Infetch`.
///
/// It is intentionally rule-based (no network / ML): it detects the vendor from
/// known brand keywords or the sender domain, extracts the payable amount with a
/// tiered strategy (labelled total → largest currency value → generic), and pulls
/// a due date from common phrasings. Amounts handle both Western (`1,234,567`) and
/// Indian (`12,34,567`) digit grouping.
struct BillParser {

    /// Builds an importable bill, or returns `nil` when the email should be skipped.
    ///
    /// The app's purpose is "don't miss a payment", so we import **every unpaid
    /// bill** — overdue, due today, or due in the future. The only emails dropped
    /// are ones that are already settled (receipts, "payment received"
    /// confirmations like a paid Zepto / Zomato order).
    static func makeBill(from email: GmailEmail, userId: UUID) -> Infetch? {

        let haystack = email.subject + "\n" + email.body

        // Skip anything that's already been paid — receipts / confirmations.
        guard !isAlreadyPaid(text: haystack) else { return nil }

        let vendor = detectVendor(subject: email.subject, body: email.body, sender: email.from)
        let amount = extractAmount(from: haystack)
        let dueDate = extractDueDate(from: haystack)
            ?? Calendar.current.date(byAdding: .day, value: 7, to: email.receivedAt)
            ?? email.receivedAt

        let category = detectCategory(vendor: vendor, body: email.body, sender: email.from)

        return Infetch(
            name: vendor,
            dueDate: dueDate,
            billDate: email.receivedAt,
            SubjectName: vendor,
            amount: amount,
            customerName: "",
            phoneNumber: nil,
            billNumber: email.id,
            isPaid: false,
            gmailMessageId: email.id,
            paidAt: nil,
            inFetchCategory: category,
            userId: userId
        )
    }

    // MARK: - Already-Paid Detection

    /// Returns `true` when the email is a payment confirmation / receipt rather
    /// than an outstanding bill. Only strong, unambiguous "settled" phrases are
    /// used so genuine "payment is due" reminders are never dropped by mistake.
    static func isAlreadyPaid(text: String) -> Bool {

        let t = text.lowercased()

        // Guard: a reminder like "your payment is due" must NOT count as paid,
        // even though it contains the word "payment".
        let dueSignals = ["is due", "due on", "due date", "pay by", "payment due",
                          "amount due", "outstanding", "please pay", "to avoid",
                          "before due"]
        if dueSignals.contains(where: { t.contains($0) }) { return false }

        let paidSignals = [
            "payment received", "payment successful", "successful payment",
            "payment was successful", "successfully paid", "paid successfully",
            "thank you for your payment", "thanks for your payment",
            "thank you for paying", "payment confirmation", "payment confirmed",
            "we have received your payment", "received your payment",
            "debited successfully", "successfully debited", "auto-debited",
            "autopay successful", "transaction successful", "payment receipt",
            "has been paid", "bill paid", "recharge successful", "order delivered"
        ]
        return paidSignals.contains { t.contains($0) }
    }

    // MARK: - Vendor Detection

    static func detectVendor(subject: String, body: String, sender: String) -> String {

        let text = (subject + " " + body + " " + sender).lowercased()

        // Telecom
        if text.contains("airtel") { return "Airtel" }
        if text.contains("jio") { return "Jio" }
        if text.contains("vi ") || text.contains("vodafone") { return "Vi" }
        if text.contains("bsnl") { return "BSNL" }

        // OTT & Subscriptions
        if text.contains("netflix") { return "Netflix" }
        if text.contains("hotstar") || text.contains("disney+") { return "Disney+ Hotstar" }
        if text.contains("spotify") { return "Spotify" }
        if text.contains("youtube premium") { return "YouTube Premium" }
        if text.contains("prime video") || text.contains("amazon prime") { return "Amazon Prime" }

        // E-Commerce — amazon check MUST come after "amazon prime"
        if text.contains("amazon") { return "Amazon" }
        if text.contains("flipkart") { return "Flipkart" }
        if text.contains("myntra") { return "Myntra" }
        if text.contains("meesho") { return "Meesho" }
        if text.contains("nykaa") { return "Nykaa" }
        if text.contains("ajio") { return "AJIO" }

        // Food
        if text.contains("swiggy") { return "Swiggy" }
        if text.contains("zomato") { return "Zomato" }
        if text.contains("blinkit") { return "Blinkit" }
        if text.contains("zepto") { return "Zepto" }

        // Electricity
        if text.contains("adani electricity") { return "Adani Electricity" }
        if text.contains("torrent power") { return "Torrent Power" }
        if text.contains("bescom") { return "BESCOM" }
        if text.contains("msedcl") { return "MSEDCL" }
        if text.contains("bses") { return "BSES" }
        if text.contains("tata power") { return "Tata Power" }

        // Banking / Finance
        if text.contains("icici") { return "ICICI Bank" }
        if text.contains("hdfc") { return "HDFC Bank" }
        if text.contains("sbi") { return "SBI" }
        if text.contains("axis bank") { return "Axis Bank" }
        if text.contains("kotak") { return "Kotak Bank" }
        if text.contains("paytm") { return "Paytm" }
        if text.contains("phonepe") { return "PhonePe" }
        if text.contains("razorpay") { return "Razorpay" }
        if text.contains("bajaj") { return "Bajaj Finance" }

        // Insurance
        if text.contains("lic ") || text.contains("life insurance corporation") { return "LIC" }
        if text.contains("hdfc life") { return "HDFC Life" }
        if text.contains("star health") { return "Star Health" }
        if text.contains("policybazaar") { return "PolicyBazaar" }

        // Travel
        if text.contains("irctc") { return "IRCTC" }
        if text.contains("makemytrip") { return "MakeMyTrip" }
        if text.contains("goibibo") { return "Goibibo" }
        if text.contains("cleartrip") { return "Cleartrip" }

        // Utilities
        if text.contains("indane") || text.contains("hp gas") || text.contains("bharat gas") { return "LPG Gas" }

        // Fallback: derive a readable name from the sender address (most reliable),
        // then from any email address found in the body.
        if let name = extractSenderDomain(from: sender) ?? extractSenderDomain(from: text) {
            return name
        }

        return "Bill"
    }

    // MARK: - Domain Fallback

    /// Derives a human-readable brand name from an email address, e.g.
    /// `noreply@email.hdfcbank.com` → `Hdfcbank`, `billing@amazon.in` → `Amazon`.
    private static func extractSenderDomain(from text: String) -> String? {
        guard let domain = firstMatch(pattern: #"[\w.+-]+@([\w.-]+\.\w{2,})"#,
                                      in: text.lowercased())?.lowercased() else { return nil }

        var labels = domain.split(separator: ".").map(String.init)

        // Strip trailing TLDs / country codes: amazon.co.in → amazon
        let tlds: Set<String> = ["com", "in", "co", "net", "org", "io", "biz", "info", "gov", "edu"]
        while let last = labels.last, tlds.contains(last), labels.count > 1 {
            labels.removeLast()
        }

        // Strip leading mail-server / department sub-labels: email.amazon → amazon
        let fluff: Set<String> = [
            "email", "mail", "mailer", "e", "mkt", "marketing", "noreply", "no-reply",
            "info", "support", "update", "updates", "news", "newsletter", "notification",
            "notifications", "alerts", "alert", "billing", "account", "accounts", "smtp",
            "send", "sender", "txn", "transaction"
        ]
        let pick = labels.reversed().first(where: { !fluff.contains($0) }) ?? labels.last
        guard let name = pick, name.count > 1 else { return nil }

        // Generic consumer mail providers carry no vendor signal.
        let generic: Set<String> = [
            "gmail", "yahoo", "outlook", "hotmail", "icloud", "proton", "protonmail",
            "ymail", "live", "msn", "rediffmail", "rediff", "zoho"
        ]
        if generic.contains(name) { return nil }

        return name.prefix(1).uppercased() + name.dropFirst()
    }

    // MARK: - Amount Detection

    /// A number that accepts Western (`1,234,567`) and Indian (`12,34,567`) grouping,
    /// or a plain run of digits, with an optional 1–2 digit decimal part.
    private static let numberPattern =
        #"(\d{1,3}(?:,\d{2,3})*(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)"#

    static func extractAmount(from text: String) -> Double? {

        let lowered = text.lowercased()

        // ── Tier 1: amounts explicitly labelled as the payable total ──────────
        // Most specific labels first so "total amount due" wins over "amount due".
        let totalLabels = [
            "total amount due", "grand total", "amount payable", "total payable",
            "net payable", "total amount", "amount due", "total due", "bill amount",
            "net amount", "amount to be paid", "order total"
        ]
        for label in totalLabels {
            // <label> … [₹|Rs|INR]? <number>   (a few separator chars allowed between)
            let pattern = label + #"[^\d₹]{0,15}(?:₹|rs\.?|inr)?\s?"# + numberPattern
            if let v = firstMatch(pattern: pattern, in: lowered), let amt = parseAmount(v) {
                return amt
            }
        }

        // ── Tier 2: every currency-tagged amount — pick the largest ───────────
        // For bills the payable figure is almost always the biggest value shown
        // (totals dwarf line items, taxes, cashback teasers, etc.).
        let currencyPatterns = [
            #"₹\s?"# + numberPattern,
            #"inr\s?"# + numberPattern,
            #"rs\.?\s?"# + numberPattern,
        ]
        var candidates: [Double] = []
        for pattern in currencyPatterns {
            candidates.append(contentsOf: allMatches(pattern: pattern, in: lowered).compactMap(parseAmount))
        }
        if let best = candidates.max() { return best }

        // ── Tier 3: generic "total: 399" style with no currency marker ────────
        let generic = #"(?:total|amount|pay|payment)[:\s]+"# + numberPattern
        if let v = firstMatch(pattern: generic, in: lowered), let amt = parseAmount(v) {
            return amt
        }

        return nil
    }

    nonisolated private static func parseAmount(_ raw: String) -> Double? {
        let cleaned = raw.replacingOccurrences(of: ",", with: "")
        guard let amount = Double(cleaned), amount > 0 else { return nil }
        return amount
    }

    // MARK: - Due Date Detection

    static func extractDueDate(from text: String) -> Date? {

        let lower = text.lowercased()

        // A date token: numeric (12/03/2026, 12-03-26) or month-name
        // (12 mar 2026, 12th march 2026, mar 12, 2026).
        let dateToken =
            #"(\d{1,2}[-/.]\d{1,2}[-/.]\d{2,4}"# +
            #"|\d{1,2}(?:st|nd|rd|th)?\s+[a-z]{3,9}\.?\s+\d{2,4}"# +
            #"|[a-z]{3,9}\.?\s+\d{1,2},?\s+\d{2,4})"#

        // Most specific phrasings first; bare "due" last to avoid false hits.
        let keywords = [
            "due on", "due date", "due by", "pay by", "payment due",
            "last date of payment", "last date", "payable by", "due"
        ]
        for kw in keywords {
            let pattern = kw + #"[:\s]+"# + dateToken
            if let match = firstMatch(pattern: pattern, in: lower), let date = parseDate(match) {
                return date
            }
        }

        return nil
    }

    // MARK: - Category

    static func detectCategory(vendor: String, body: String, sender: String) -> InfetchCategory {

        let text = (vendor + " " + body + " " + sender).lowercased()

        if text.contains("insurance") { return .insurance }
        if text.contains("bank") || text.contains("loan") || text.contains("credit card") || text.contains("emi") { return .finance }
        if text.contains("policy") { return .policy }

        return .bill
    }

    // MARK: - Regex Helpers

    /// Returns capture group 1 of the first match, or `nil`.
    static func firstMatch(pattern: String, in text: String) -> String? {

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }

        let nsrange = NSRange(text.startIndex..., in: text)

        guard let match = regex.firstMatch(in: text, options: [], range: nsrange),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: text) else { return nil }

        return String(text[range])
    }

    /// Returns capture group 1 of every match.
    static func allMatches(pattern: String, in text: String) -> [String] {

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }

        let nsrange = NSRange(text.startIndex..., in: text)

        return regex.matches(in: text, options: [], range: nsrange).compactMap { match in
            guard match.numberOfRanges > 1,
                  let range = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[range])
        }
    }

    // MARK: - Date Parsing

    static func parseDate(_ value: String) -> Date? {

        // Drop ordinal suffixes: "12th" → "12"
        let normalized = value
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: #"(\d)(st|nd|rd|th)"#, with: "$1",
                                  options: [.regularExpression, .caseInsensitive])

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        // dd/MM first — Indian bills are day-first. (Genuinely ambiguous dates like
        // 03/04/2026 are read as 3 April, the regional convention here.)
        let formats = [
            "dd/MM/yyyy", "dd-MM-yyyy", "dd.MM.yyyy", "dd/MM/yy", "dd-MM-yy", "dd.MM.yy",
            "MM/dd/yyyy", "MM-dd-yyyy", "yyyy-MM-dd",
            "dd MMM yyyy", "dd MMMM yyyy", "dd MMM yy",
            "MMM dd yyyy", "MMMM dd yyyy", "MMM dd, yyyy", "MMMM dd, yyyy"
        ]

        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: normalized) { return date }
        }

        return nil
    }
}
