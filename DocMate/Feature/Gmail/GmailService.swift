//
//  GmailService.swift
//  DocMate
//
//  Google OAuth PKCE flow — works with iOS OAuth Client ID
//  (response_type=token is blocked by Google since 2019, PKCE use karo)
//
//  Setup:
//  1. console.cloud.google.com → Credentials → Create → OAuth Client ID → iOS
//  2. Bundle ID daalo (Xcode → Target → General → Bundle Identifier)
//  3. Client ID copy karo neeche
//  4. Info.plist → URL Types → + → URL Schemes → reversed client ID daalo
//     e.g. com.googleusercontent.apps.123456-abc
//

import Foundation
import AuthenticationServices
import CryptoKit
import UIKit

// MARK: - Email Model
struct GmailEmail: Identifiable {
    let id: String
    let subject: String
    let body: String
    let receivedAt: Date
}

// MARK: - GmailService
class GmailService: NSObject {

    static let shared = GmailService()
    private override init() { super.init() }

    // ── APNI CONFIG YAHAN DAALO ───────────────────────────────────────────
    // Google Cloud Console → Credentials → iOS OAuth 2.0 Client ID
    private let clientID =
    "748158363587-a8al5uj74lndf8cguq25rkqvp76ea8e3.apps.googleusercontent.com"

    private let redirectURI =
    "com.googleusercontent.apps.748158363587-a8al5uj74lndf8cguq25rkqvp76ea8e3:/oauth2callback"
    // ──────────────────────────────────────────────────────────────────────

    private var accessToken: String? {
        get { UserDefaults.standard.string(forKey: "gmail_access_token") }
        set { UserDefaults.standard.set(newValue, forKey: "gmail_access_token") }
    }
    var isSignedIn: Bool { accessToken != nil }
    func signOut() {
        UserDefaults.standard.removeObject(
            forKey: "gmail_access_token"
        )
    }

    // MARK: - Sign In (PKCE flow)
    func signIn(presenting viewController: UIViewController) async throws {
        // 1. PKCE verifier + challenge generate karo
        UserDefaults.standard.removeObject(forKey: "gmail_access_token")
        let verifier  = pkceVerifier()
        let challenge = pkceChallenge(from: verifier)

        let scope = "https://www.googleapis.com/auth/gmail.readonly"
        let state = UUID().uuidString

        var comps = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        comps.queryItems = [
            .init(name: "client_id",             value: clientID),
            .init(name: "redirect_uri",          value: redirectURI),
            .init(name: "response_type",         value: "code"),        // PKCE uses code
            .init(name: "scope",                 value: scope),
            .init(name: "state",                 value: state),
            .init(name: "code_challenge",        value: challenge),
            .init(name: "code_challenge_method", value: "S256"),
        ]

        guard let authURL = comps.url,
              let scheme  = URL(string: redirectURI)?.scheme else {
            throw GmailError.configurationError
        }

        // 2. Browser mein auth karo, code wapas lo
        let code: String = try await withCheckedThrowingContinuation { cont in
            DispatchQueue.main.async {
                let ctx = PresentationContextProvider(vc: viewController)
                let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: scheme) { url, err in
                    if let err { cont.resume(throwing: err); return }
                    guard let url else { cont.resume(throwing: GmailError.authFailed); return }

                    // query mein code milega
                    let params = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                        .queryItems?.reduce(into: [String:String]()) { $0[$1.name] = $1.value }
                        ?? [:]

                    guard let code = params["code"] else {
                        cont.resume(throwing: GmailError.authFailed); return
                    }
                    cont.resume(returning: code)
                }
                session.presentationContextProvider = ctx
                session.prefersEphemeralWebBrowserSession = false
                session.start()
            }
        }

        // 3. Code ko access_token se exchange karo
        self.accessToken = try await exchangeCode(code, verifier: verifier)
    }

    // MARK: - Token Exchange
    private func exchangeCode(_ code: String, verifier: String) async throws -> String {
        var req = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "code":          code,
            "client_id":     clientID,
            "redirect_uri":  redirectURI,
            "grant_type":    "authorization_code",
            "code_verifier": verifier,
        ]
        req.httpBody = body
            .map { "\($0.key)=\($0.value.urlEncoded)" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: req)
        let json = try JSONDecoder().decode(TokenResponse.self, from: data)

        guard let token = json.accessToken else { throw GmailError.authFailed }
        return token
    }

    // MARK: - PKCE Helpers
    private func pkceVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func pkceChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    // MARK: - Fetch Emails
    func fetchBillEmails() async throws -> [GmailEmail] {
        guard let accessToken else { throw GmailError.notSignedIn }

        let query = "subject:(bill OR invoice OR payment OR due OR EMI OR recharge OR order OR receipt OR statement OR premium OR subscription) newer_than:30d"
        let listURL = URL(string: "https://gmail.googleapis.com/gmail/v1/users/me/messages?q=\(query.urlEncoded)&maxResults=15")!

        var listReq = URLRequest(url: listURL)
        listReq.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (listData, _) = try await URLSession.shared.data(for: listReq)
        let listResponse  = try JSONDecoder().decode(MessageListResponse.self, from: listData)
        guard let messages = listResponse.messages else { return [] }

        var emails: [GmailEmail] = []
        for msg in messages {
            if let email = try? await fetchMessage(id: msg.id, token: accessToken) {
                emails.append(email)
            }
        }
        return emails
    }

    private func fetchMessage(id: String, token: String) async throws -> GmailEmail {
        let url = URL(string: "https://gmail.googleapis.com/gmail/v1/users/me/messages/\(id)?format=full")!
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: req)
        let msg = try JSONDecoder().decode(MessageDetail.self, from: data)

        let subject = msg.payload.headers.first(where: { $0.name == "Subject" })?.value ?? "No Subject"
        let dateStr = msg.payload.headers.first(where: { $0.name == "Date" })?.value ?? ""

        return GmailEmail(id: id, subject: subject, body: extractBody(from: msg.payload), receivedAt: parseDate(dateStr))
    }

    private func extractBody(from payload: MessagePayload) -> String {
        if let d = payload.body.data, !d.isEmpty { return decodeBase64URL(d) }
        if let parts = payload.parts {
            for p in parts where p.mimeType == "text/plain" { if let d = p.body.data { return decodeBase64URL(d) } }
            for p in parts where p.mimeType == "text/html"  { if let d = p.body.data { return decodeBase64URL(d).strippingHTML() } }
        }
        return ""
    }

    private func decodeBase64URL(_ s: String) -> String {
        let fixed  = s.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        let padded = fixed + String(repeating: "=", count: (4 - fixed.count % 4) % 4)
        guard let data = Data(base64Encoded: padded) else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }

    private func parseDate(_ s: String) -> Date {
        let f = DateFormatter(); f.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return f.date(from: s) ?? Date()
    }
}

// MARK: - Presentation Context
private class PresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    let vc: UIViewController
    init(vc: UIViewController) { self.vc = vc }
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        if let window = vc.view.window {
            return window
        }
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            return window
        }
        
        fatalError("No valid window available")
    }
}

// MARK: - Errors
enum GmailError: LocalizedError {
    case notSignedIn, authFailed, configurationError
    var errorDescription: String? {
        switch self {
        case .notSignedIn:        return "Gmail se sign in nahi hai"
        case .authFailed:         return "Google login fail ho gaya"
        case .configurationError: return "Google OAuth configure nahi hai — clientID set karo"
        }
    }
}

// MARK: - Codable Models
private struct TokenResponse: Codable {
    let accessToken: String?
    enum CodingKeys: String, CodingKey { case accessToken = "access_token" }
}
private struct MessageListResponse: Codable { let messages: [MessageRef]? }
private struct MessageRef: Codable { let id: String }
private struct MessageDetail: Codable { let payload: MessagePayload }
private struct MessagePayload: Codable {
    let headers: [Header]; let body: BodyData; let parts: [Part]?; let mimeType: String?
}
private struct Header: Codable { let name: String; let value: String }
private struct BodyData: Codable { let data: String? }
private struct Part: Codable { let mimeType: String?; let body: BodyData }

private extension String {
    var urlEncoded: String { addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self }
    func strippingHTML() -> String {
        guard let data = data(using: .utf8) else { return self }
        let opts: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        return (try? NSAttributedString(data: data, options: opts, documentAttributes: nil))?.string ?? self
    }
}
