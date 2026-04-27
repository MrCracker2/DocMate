//
//  GeminiExtractor.swift
//  DocMate
//
//  LOCATION: DocMate/Core/AI/GeminiExtractor.swift
//
//  Kya karta hai:
//  - Email text ko Gemini AI ko bhejta hai
//  - AI se JSON mein extracted bill info wapas leta hai
//  - amount, due_date, vendor_name, category extract karta hai
//
//  Setup:
//  - aistudio.google.com pe jaao
//  - API key banao (free hai)
//  - Neeche GEMINI_API_KEY replace karo
//

import Foundation

// MARK: - Extracted Bill Model
struct ExtractedBill: Codable {
    let vendorName: String
    let amount: Double?
    let dueDate: String?       // "YYYY-MM-DD" format ya nil
    let billDate: String?      // "YYYY-MM-DD" format ya nil
    let category: String       // bill / insurance / finance / policy / other

    enum CodingKeys: String, CodingKey {
        case vendorName  = "vendor_name"
        case amount      = "amount"
        case dueDate     = "due_date"
        case billDate    = "bill_date"
        case category    = "category"
    }
}

// MARK: - GeminiExtractor
class GeminiExtractor {

    static let shared = GeminiExtractor()
    private init() {}

    // APNI GEMINI API KEY YAHAN DAALO
    // aistudio.google.com → Get API Key
    private let apiKey = "AIzaSyCzTWrWxwNarlk9kWYVtpU0tHL5n5bkjwM"

    private let model = "gemini-2.0-flash"

    // MARK: - Extract
    /// Email text se bill information extract karo using Gemini AI
    func extract(from emailText: String, subject: String = "") async throws -> ExtractedBill? {

        let prompt = buildPrompt(emailText: emailText, subject: subject)
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"

        guard let url = URL(string: urlString) else { return nil }

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [["text": prompt]]
                ]
            ],
            "generationConfig": [
                "temperature": 0.1,        // low temperature = consistent JSON output
                "maxOutputTokens": 300
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.apiError
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "No body"

            print("Gemini HTTP Code:", httpResponse.statusCode)
            print("Gemini Response:", body)

            throw GeminiError.apiError
        }
        return parseResponse(data: data)
    }

    // MARK: - Private: Prompt Builder
    private func buildPrompt(emailText: String, subject: String) -> String {
        """
        Extract bill/invoice information from this email. Return ONLY valid JSON, no explanation, no markdown, no code block.

        Required JSON format:
        {
          "vendor_name": "company or service name",
          "amount": 1234.56,
          "due_date": "YYYY-MM-DD",
          "bill_date": "YYYY-MM-DD",
          "category": "bill"
        }

        Rules:
        - amount should be a number (no currency symbol)
        - dates must be YYYY-MM-DD format, use null if not found
        - category must be one of: bill, insurance, finance, policy, other
        - If information not found, use null for that field
        - vendor_name should never be null, guess from context

        Email Subject: \(subject)

        Email Content:
        \(emailText.prefix(2000))
        """
    }

    // MARK: - Private: Parse Gemini Response
    private func parseResponse(data: Data) -> ExtractedBill? {
        do {
            let response = try JSONDecoder().decode(GeminiResponse.self, from: data)
            guard let text = response.candidates.first?.content.parts.first?.text else { return nil }

            // JSON clean karo (kabhi kabhi Gemini backticks deta hai)
            let cleaned = text
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard let jsonData = cleaned.data(using: .utf8) else { return nil }
            return try JSONDecoder().decode(ExtractedBill.self, from: jsonData)

        } catch {
            print("GeminiExtractor parse error: \(error)")
            return nil
        }
    }
}

// MARK: - Error
enum GeminiError: LocalizedError {
    case apiError
    var errorDescription: String? { "Gemini API se data nahi aaya" }
}

// MARK: - Gemini API Response Models
private struct GeminiResponse: Codable {
    let candidates: [Candidate]
}

private struct Candidate: Codable {
    let content: Content
}

private struct Content: Codable {
    let parts: [Part]
}

private struct Part: Codable {
    let text: String
}
