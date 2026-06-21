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
import Security
import UIKit

// MARK: - Email Model
struct GmailEmail: Identifiable {
    let id: String
    let subject: String
    let from: String
    /// Plain-text body, used by the heuristic parser.
    let body: String
    /// Raw HTML body (un-stripped). Carries the machine-readable schema.org
    /// `Invoice` markup that gives exact amount / due date, so it must be kept
    /// separately from `body` (which has the HTML — and the markup — removed).
    let html: String
    let receivedAt: Date

    init(id: String, subject: String, from: String,
         body: String, html: String = "", receivedAt: Date) {
        self.id = id
        self.subject = subject
        self.from = from
        self.body = body
        self.html = html
        self.receivedAt = receivedAt
    }
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

    // MARK: - Secure Token Storage (Keychain)
    // Tokens are stored in the Keychain rather than UserDefaults so they are
    // encrypted at rest and not exposed in plain device backups.

    private enum Key {
        static let accessToken  = "gmail_access_token"
        static let refreshToken = "gmail_refresh_token"
        static let expiry       = "gmail_token_expiry"   // epoch seconds, as String
        static let email        = "gmail_connected_email"
    }

    /// The Gmail address of the currently connected account, if any. Shown in
    /// the UI so the user can see which mailbox is linked.
    var connectedEmail: String? {
        get { KeychainStore.read(Key.email) }
        set { KeychainStore.set(newValue, for: Key.email) }
    }

    private var accessToken: String? {
        get { KeychainStore.read(Key.accessToken) }
        set { KeychainStore.set(newValue, for: Key.accessToken) }
    }

    private var refreshToken: String? {
        get { KeychainStore.read(Key.refreshToken) }
        set { KeychainStore.set(newValue, for: Key.refreshToken) }
    }

    /// Absolute time the current access token stops being valid.
    private var tokenExpiry: Date? {
        get { KeychainStore.read(Key.expiry).flatMap { Double($0) }.map { Date(timeIntervalSince1970: $0) } }
        set { KeychainStore.set(newValue.map { String($0.timeIntervalSince1970) }, for: Key.expiry) }
    }

    /// Signed in as long as we can obtain a token (a refresh token is enough —
    /// the access token may be expired but renewable without user interaction).
    var isSignedIn: Bool { refreshToken != nil || accessToken != nil }

    func signOut() {
        KeychainStore.delete(Key.accessToken)
        KeychainStore.delete(Key.refreshToken)
        KeychainStore.delete(Key.expiry)
        KeychainStore.delete(Key.email)
    }

    // MARK: - Sign In (PKCE flow)
    func signIn(presenting viewController: UIViewController) async throws {
        // 1. Clear any previous session and generate a fresh PKCE pair.
        signOut()
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
            // Request a refresh token so we can renew access without forcing the
            // user to log in again every hour. `prompt=consent` guarantees Google
            // returns a refresh_token even on repeat authorisations.
            .init(name: "access_type",           value: "offline"),
            .init(name: "prompt",                value: "consent"),
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

        // 3. Exchange the authorization code for access + refresh tokens.
        try await exchangeCode(code, verifier: verifier)

        // 4. Record which mailbox is now connected so the UI can display it.
        try? await fetchProfileEmail()
    }

    // MARK: - Connected Account

    /// Looks up the signed-in account's email via the Gmail profile endpoint
    /// (works with the `gmail.readonly` scope) and caches it in the Keychain.
    @discardableResult
    func fetchProfileEmail() async throws -> String {
        let token = try await validAccessToken()
        let url = URL(string: "https://gmail.googleapis.com/gmail/v1/users/me/profile")!
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: req)
        let profile = try JSONDecoder().decode(GmailProfile.self, from: data)
        connectedEmail = profile.emailAddress
        return profile.emailAddress
    }

    // MARK: - Token Exchange
    private func exchangeCode(_ code: String, verifier: String) async throws {
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
        store(tokenResponse: json, fallbackToken: token)
    }

    // MARK: - Token Lifecycle

    /// Persists a token response. The refresh token is only returned on the
    /// first consent, so we keep the existing one when the response omits it.
    private func store(tokenResponse: TokenResponse, fallbackToken: String) {
        accessToken = tokenResponse.accessToken ?? fallbackToken
        if let refresh = tokenResponse.refreshToken {
            refreshToken = refresh
        }
        // Renew a minute early to avoid using a token that expires mid-request.
        let lifetime = TimeInterval(tokenResponse.expiresIn ?? 3600)
        tokenExpiry = Date().addingTimeInterval(lifetime - 60)
    }

    /// Returns a valid access token, transparently refreshing it when expired.
    private func validAccessToken() async throws -> String {
        if let token = accessToken, let expiry = tokenExpiry, expiry > Date() {
            return token
        }
        return try await refreshAccessToken()
    }

    /// Uses the stored refresh token to obtain a new access token without any
    /// user interaction. Throws `notSignedIn` if the user never consented.
    private func refreshAccessToken() async throws -> String {
        guard let refreshToken else { throw GmailError.notSignedIn }

        var req = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "client_id":     clientID,
            "refresh_token": refreshToken,
            "grant_type":    "refresh_token",
        ]
        req.httpBody = body
            .map { "\($0.key)=\($0.value.urlEncoded)" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: req)
        let json = try JSONDecoder().decode(TokenResponse.self, from: data)

        guard let token = json.accessToken else {
            // Refresh token revoked or expired — force a fresh sign-in.
            signOut()
            throw GmailError.notSignedIn
        }
        store(tokenResponse: json, fallbackToken: token)
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
        let accessToken = try await validAccessToken()

        // Three OR'd signals, far wider than a subject-keyword scan:
        //   1. category:purchases — Gmail's own ML already tags receipts/bills,
        //      catching them even when the subject has no obvious keyword.
        //   2. from:(known biller senders) — bills almost always arrive from
        //      billing/noreply/statements@... addresses.
        //   3. subject keywords — the original fallback for everything else.
        let senderHints = "from:(billing OR noreply OR no-reply OR statements OR " +
                          "estatement OR alerts OR payments OR invoice OR accounts)"
        let subjectHints = "subject:(bill OR invoice OR payment OR due OR EMI OR " +
                           "recharge OR statement OR premium OR policy)"
        let query = "(category:purchases OR \(senderHints) OR \(subjectHints)) newer_than:45d"
        let listURL = URL(string: "https://gmail.googleapis.com/gmail/v1/users/me/messages?q=\(query.urlEncoded)&maxResults=25")!

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

    /// Fetches a single email by its Gmail message id, refreshing the access
    /// token if needed. Used to show a bill's source email inside the app.
    func fetchEmail(id: String) async throws -> GmailEmail {
        let token = try await validAccessToken()
        return try await fetchMessage(id: id, token: token)
    }

    private func fetchMessage(id: String, token: String) async throws -> GmailEmail {
        let url = URL(string: "https://gmail.googleapis.com/gmail/v1/users/me/messages/\(id)?format=full")!
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: req)
        let msg = try JSONDecoder().decode(MessageDetail.self, from: data)

        let subject = msg.payload.headers.first(where: { $0.name == "Subject" })?.value ?? "No Subject"
        let from    = msg.payload.headers.first(where: { $0.name == "From" })?.value ?? ""
        let dateStr = msg.payload.headers.first(where: { $0.name == "Date" })?.value ?? ""

        let (text, html) = extractBodies(from: msg.payload)
        return GmailEmail(id: id, subject: subject, from: from,
                          body: text, html: html, receivedAt: parseDate(dateStr))
    }

    /// Extracts both a plain-text body and the raw HTML body, walking the full
    /// MIME tree. Real bill emails are commonly `multipart/mixed` →
    /// `multipart/alternative` nested several levels deep, so a single-level scan
    /// misses the content. The raw HTML is returned untouched so the schema.org
    /// `Invoice` markup inside it survives for `BillParser` to read.
    private func extractBodies(from payload: MessagePayload) -> (text: String, html: String) {
        // Raw HTML — kept verbatim (markup lives inside <script> tags).
        var html = firstBody(mimeType: "text/html", parts: payload.parts) ?? ""
        if html.isEmpty, payload.mimeType == "text/html", let d = payload.body.data {
            html = decodeBase64URL(d)
        }

        // Plain text — prefer a real text/plain part, else strip the HTML.
        if let plain = firstBody(mimeType: "text/plain", parts: payload.parts), !plain.isEmpty {
            return (plain, html)
        }
        if !html.isEmpty {
            return (html.strippingHTML(), html)
        }
        // Single-part, non-HTML message: the body sits directly on the payload.
        if let d = payload.body.data, !d.isEmpty {
            return (decodeBase64URL(d), html)
        }
        return ("", html)
    }

    /// Depth-first search for the first non-empty part of the given MIME type.
    private func firstBody(mimeType: String, parts: [Part]?) -> String? {
        guard let parts else { return nil }
        for p in parts {
            if p.mimeType == mimeType, let d = p.body.data, !d.isEmpty {
                let decoded = decodeBase64URL(d)
                if !decoded.isEmpty { return decoded }
            }
            if let nested = firstBody(mimeType: mimeType, parts: p.parts) {
                return nested
            }
        }
        return nil
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
        case .notSignedIn:        return "You're not signed in to Gmail."
        case .authFailed:         return "Google sign-in failed. Please try again."
        case .configurationError: return "Gmail is not configured correctly."
        }
    }
}

// MARK: - Keychain Helper
/// Minimal generic-password Keychain wrapper for storing OAuth tokens securely.
private enum KeychainStore {
    private static let service = "com.docmate.gmail"

    private static func query(_ account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    static func read(_ account: String) -> String? {
        var q = query(account)
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Sets a value, or removes the entry when `value` is nil.
    static func set(_ value: String?, for account: String) {
        guard let value, let data = value.data(using: .utf8) else {
            delete(account)
            return
        }
        let attrs: [String: Any] = [kSecValueData as String: data]
        if SecItemUpdate(query(account) as CFDictionary, attrs as CFDictionary) == errSecItemNotFound {
            var insert = query(account)
            insert[kSecValueData as String] = data
            insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            SecItemAdd(insert as CFDictionary, nil)
        }
    }

    static func delete(_ account: String) {
        SecItemDelete(query(account) as CFDictionary)
    }
}

// MARK: - Codable Models
private struct TokenResponse: Codable {
    let accessToken: String?
    let refreshToken: String?
    let expiresIn: Int?
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}
private struct GmailProfile: Codable { let emailAddress: String }
private struct MessageListResponse: Codable { let messages: [MessageRef]? }
private struct MessageRef: Codable { let id: String }
private struct MessageDetail: Codable { let payload: MessagePayload }
private struct MessagePayload: Codable {
    let headers: [Header]; let body: BodyData; let parts: [Part]?; let mimeType: String?
}
private struct Header: Codable { let name: String; let value: String }
private struct BodyData: Codable { let data: String? }
private struct Part: Codable { let mimeType: String?; let body: BodyData; let parts: [Part]? }

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
