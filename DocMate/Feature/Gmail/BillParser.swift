//
//  BillParser.swift
//  DocMate
//
//
//  BillParser.swift
//  DocMate
//
//  Created by Shashwat kumar on 27/04/26.
//

//
//  BillParser.swift
//  DocMate
//

import Foundation

struct BillParser {

    static func makeBill(from email: GmailEmail, userId: UUID) -> Infetch {

        let vendor = detectVendor(from: email.subject, body: email.body)
        let amount = extractAmount(from: email.subject + " " + email.body)
        let dueDate = extractDueDate(from: email.subject + " " + email.body) ?? Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let category = detectCategory(from: vendor, body: email.body)

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

    // MARK: - Vendor Detection

    static func detectVendor(from subject: String, body: String) -> String {

        let text = (subject + " " + body).lowercased()

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

        // Fallback: try to extract sender domain from email body (e.g. "noreply@amazon.in")
        if let domain = extractSenderDomain(from: subject + " " + body) {
            return domain
        }

        return "Bill"
    }

    // MARK: - Domain Fallback
    /// Tries to extract a readable name from email-like addresses in the text
    private static func extractSenderDomain(from text: String) -> String? {
        let pattern = #"[\w.+-]+@([\w-]+)\."#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: text) else { return nil }

        let domain = String(text[range])
        // Skip generic mail servers
        let ignore = ["gmail", "yahoo", "outlook", "hotmail", "noreply", "no-reply", "info", "support", "mail"]
        if ignore.contains(domain.lowercased()) { return nil }

        // Capitalize first letter
        return domain.prefix(1).uppercased() + domain.dropFirst()
    }

    // MARK: - Amount Detection

    static func extractAmount(from text: String) -> Double? {

        // Order matters: try most-specific patterns first
        let patterns = [
            // ₹ symbol (with or without space, optional comma in number)
            #"₹\s?(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?)"#,

            // INR keyword (case-insensitive handled by lowercasing below)
            #"inr\s?(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?)"#,

            // Rs. or Rs with optional dot and optional space
            #"rs\.?\s?(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?)"#,

            // "total: 399" or "amount: 399" or "pay 399"
            #"(?:total|amount|pay|payment|order total)[:\s]+(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?)"#,
        ]

        let lowered = text.lowercased()

        for pattern in patterns {
            if let value = firstMatch(pattern: pattern, in: lowered) {
                // Remove commas used as thousand separators
                let cleaned = value.replacingOccurrences(of: ",", with: "")
                if let amount = Double(cleaned), amount > 0 {
                    return amount
                }
            }
        }

        return nil
    }

    // MARK: - Due Date Detection

    static func extractDueDate(from text: String) -> Date? {

        let lower = text.lowercased()

        if let match = firstMatch(pattern: #"due on (\d{1,2}[-/]\d{1,2}[-/]\d{2,4})"#, in: lower) {
            return parseDate(match)
        }

        if let match = firstMatch(pattern: #"due date[: ]+(\d{1,2}[-/]\d{1,2}[-/]\d{2,4})"#, in: lower) {
            return parseDate(match)
        }

        if let match = firstMatch(pattern: #"pay by[: ]+(\d{1,2}[-/]\d{1,2}[-/]\d{2,4})"#, in: lower) {
            return parseDate(match)
        }

        if let match = firstMatch(pattern: #"last date[: ]+(\d{1,2}[-/]\d{1,2}[-/]\d{2,4})"#, in: lower) {
            return parseDate(match)
        }

        return nil
    }

    // MARK: - Category

    static func detectCategory(from vendor: String, body: String) -> InfetchCategory {

        let text = (vendor + " " + body).lowercased()

        if text.contains("insurance") { return .insurance }
        if text.contains("bank") || text.contains("loan") || text.contains("credit card") || text.contains("emi") { return .finance }
        if text.contains("policy") { return .policy }

        return .bill
    }

    // MARK: - Helpers

    static func firstMatch(pattern: String, in text: String) -> String? {

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }

        let nsrange = NSRange(text.startIndex..., in: text)

        guard let match = regex.firstMatch(in: text, options: [], range: nsrange),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: text) else { return nil }

        return String(text[range])
    }

    static func parseDate(_ value: String) -> Date? {

        let formats = [
            "dd/MM/yyyy",
            "dd-MM-yyyy",
            "MM/dd/yyyy",
            "MM-dd-yyyy",
            "dd/MM/yy",
            "dd-MM-yy"
        ]

        let formatter = DateFormatter()

        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: value) {
                return date
            }
        }

        return nil
    }
}
