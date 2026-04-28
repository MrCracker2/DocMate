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

        if text.contains("airtel") { return "Airtel" }
        if text.contains("jio") { return "Jio" }
        if text.contains("vi ") || text.contains("vodafone") { return "Vi" }
        if text.contains("bsnl") { return "BSNL" }
        if text.contains("netflix") { return "Netflix" }
        if text.contains("amazon prime") { return "Amazon Prime" }
        if text.contains("adani electricity") { return "Adani Electricity" }
        if text.contains("torrent power") { return "Torrent Power" }
        if text.contains("icici") { return "ICICI Bank" }
        if text.contains("hdfc") { return "HDFC Bank" }
        if text.contains("sbi") { return "SBI" }

        return "Bill"
    }

    // MARK: - Amount Detection

    static func extractAmount(from text: String) -> Double? {

        let patterns = [
            #"₹\s?(\d+[.,]?\d*)"#,
            #"rs\.?\s?(\d+[.,]?\d*)"#,
            #"inr\s?(\d+[.,]?\d*)"#
        ]

        for pattern in patterns {
            if let value = firstMatch(pattern: pattern, in: text.lowercased()) {
                let cleaned = value.replacingOccurrences(of: ",", with: "")
                return Double(cleaned)
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

        return nil
    }

    // MARK: - Category

    static func detectCategory(from vendor: String, body: String) -> InfetchCategory {

        let text = (vendor + " " + body).lowercased()

        if text.contains("insurance") { return .insurance }
        if text.contains("bank") || text.contains("loan") || text.contains("credit card") { return .finance }
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
