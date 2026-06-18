//
//  SupabaseManager.swift
//  DocMate
//
//  Created by Shashwat kumar on 23/04/26.
//

import Foundation
import Supabase

class SupabaseManager {
    
    static let shared = SupabaseManager()
    
    let client = SupabaseClient(
        supabaseURL: URL(string: "https://cvzsenyykycuzspnkihz.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN2enNlbnl5a3ljdXpzcG5raWh6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODExMDM4MzUsImV4cCI6MjA5NjY3OTgzNX0.BAE9UsDfBQZaPmx8zrFYzGb-BTxnPsLz28B1d23BYKM"
    )
    
    // MARK: - Auth
    
    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(
            email: email,
            password: password
        )
    }
    
    func signUp(email: String, password: String, name: String, phone: Int?, dateOfBirth: Date?, gender: String?) async throws {
        let response = try await client.auth.signUp(
            email: email,
            password: password
        )
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let dobString = dateOfBirth.map {
            formatter.string(from: $0)
        }
        
        // Update the profile row (trigger already created it)
        let profile = User(
            id: response.user.id,
            name: name,
            phone: phone,
            dateOfBirth: dobString,
            gender: gender
        )
        try await client
            .from("profiles")
            .upsert(profile)
            .execute()
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    func currentSession() async throws -> Session? {
        try await client.auth.session
    }
    
    /// Get the currently logged-in user's UUID
    var currentUserId: UUID? {
        get async {
            try? await client.auth.session.user.id
        }
    }
    
    // MARK: - Profile (profiles table)
    
    func fetchProfile() async throws -> User {
        guard let userId = await currentUserId else {
            throw NSError(domain: "DocMate", code: 0)
        }

        let profiles: [User] = try await client
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .execute()
            .value

        if let profile = profiles.first {
            print("Fetched profile:", profile)
            return profile
        }

        let newProfile = User(id: userId, name: "")
        try await client
            .from("profiles")
            .upsert(newProfile)
            .execute()

        return newProfile
    }
    func updateProfile(_ profile: User) async throws {
        try await client
            .from("profiles")
            .update(profile)
            .eq("id", value: profile.id)
            .execute()
    }
    
    // MARK: - Categories
    
    func fetchCategories() async throws -> [Category] {
        try await client
            .from("categories")
            .select()
            .execute()
            .value
    }
    
    func insertCategory(_ category: Category) async throws {
        try await client
            .from("categories")
            .insert(category)
            .execute()
    }
    
    func deleteCategory(id: UUID) async throws {
        try await client
            .from("categories")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    func updateCategoryName(id: UUID, newName: String) async throws {
        try await client
            .from("categories")
            .update(["name": newName])
            .eq("id", value: id)
            .execute()
    }
    
    // MARK: - Documents
    
    func fetchDocuments() async throws -> [Document] {
        try await client
            .from("documents")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    
    func insertDocument(_ document: Document) async throws {
        try await client
            .from("documents")
            .insert(document)
            .execute()
    }
    
    func updateDocument(_ document: Document) async throws {
        try await client
            .from("documents")
            .update(document)
            .eq("id", value: document.id)
            .execute()
    }
    
    func deleteDocument(id: UUID) async throws {
        try await client
            .from("documents")
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    // MARK: - Tags
    
    func fetchTags() async throws -> [Tag] {
        try await client
            .from("tags")
            .select()
            .execute()
            .value
    }
    
    func insertTag(_ tag: Tag) async throws {
        try await client
            .from("tags")
            .insert(tag)
            .execute()
    }
    
    func deleteTag(id: UUID) async throws {
        try await client
            .from("tags")
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    // MARK: - Bills
    
    func fetchBills() async throws -> [Infetch] {

        let response = try await client
            .from("bills")
            .select()
            .execute()

        let decoder = JSONDecoder()

        decoder.dateDecodingStrategy = .custom { decoder in

            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)

            // Format 1: 2026-05-04
            formatter.dateFormat = "yyyy-MM-dd"
            if let date = formatter.date(from: value) {
                return date
            }

            // Format 2: 2026-05-04T00:00:00Z
            let iso = ISO8601DateFormatter()

            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso.date(from: value) {
                return date
            }

            iso.formatOptions = [.withInternetDateTime]
            if let date = iso.date(from: value) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date format: \(value)"
            )
        }

        return try decoder.decode([Infetch].self, from: response.data)
    }
    
    func billExists(messageId: String) async throws -> Bool {
        let rows: [Infetch] = try await client
            .from("bills")
            .select()
            .eq("gmail_message_id", value: messageId)
            .execute()
            .value

        return !rows.isEmpty
    }


    func insertBill(_ bill: Infetch) async throws {
        try await client
            .from("bills")
            .insert(bill)
            .execute()
    }
    
    func updateBill(_ bill: Infetch) async throws {
        try await client
            .from("bills")
            .update(bill)
            .eq("id", value: bill.id)
            .execute()
    }
    
    func deleteBill(id: UUID) async throws {
        try await client
            .from("bills")
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    // MARK: - Storage (PDF files)
    
    /// Upload a PDF to Supabase Storage. Path: "{userId}/{docId}.pdf"
//    func uploadPDF(data: Data, userId: UUID, documentId: UUID) async throws -> String {
//        let path = "\(userId)/\(documentId).pdf"
//        try await client.storage
//            .from("documents")
//            .upload(path, data: data, options: .init(contentType: "application/pdf"))
//        return path
//    }
//
    
    func uploadPDF(data: Data, userId: UUID, documentId: UUID) async throws -> String {

        let path = "\(userId.uuidString.lowercased())/\(documentId.uuidString.lowercased()).pdf"

        try await client.storage
            .from("documents")
            .upload(path,
                    data: data,
                    options: .init(contentType: "application/pdf"))

        return path
    }
    /// Download any file from the documents bucket.
    func downloadStorageFile(path: String) async throws -> Data {
        try await client.storage
            .from("documents")
            .download(path: path)
    }

    /// Download a PDF from Supabase Storage
    func downloadPDF(path: String) async throws -> Data {
        try await downloadStorageFile(path: path)
    }

    // MARK: - Thumbnails (tiny previews, to avoid downloading full PDFs)

    /// Storage path of the small thumbnail that parallels a PDF's path.
    /// "uid/<id>.pdf" → "uid/thumb_<id>.jpg"
    nonisolated static func thumbnailPath(forPDFPath pdfPath: String) -> String {
        let dir = (pdfPath as NSString).deletingLastPathComponent
        let base = ((pdfPath as NSString).lastPathComponent as NSString).deletingPathExtension
        let file = "thumb_\(base).jpg"
        return dir.isEmpty ? file : "\(dir)/\(file)"
    }

    /// Uploads (or overwrites) a small JPEG thumbnail next to the PDF.
    @discardableResult
    func uploadThumbnail(data: Data, userId: UUID, documentId: UUID) async throws -> String {
        let path = "\(userId.uuidString.lowercased())/thumb_\(documentId.uuidString.lowercased()).jpg"
        try await client.storage
            .from("documents")
            .upload(path,
                    data: data,
                    options: .init(contentType: "image/jpeg", upsert: true))
        return path
    }

    /// Delete a PDF from Supabase Storage
    func deletePDF(path: String) async throws {
        try await client.storage
            .from("documents")
            .remove(paths: [path])
    }

    /// Delete a document's PDF and its thumbnail together.
    func deleteStoredFiles(pdfPath: String) async throws {
        let thumb = Self.thumbnailPath(forPDFPath: pdfPath)
        try await client.storage
            .from("documents")
            .remove(paths: [pdfPath, thumb])
    }
    func deleteCurrentUserData() async throws {
        guard let userId = await currentUserId else { return }

        try await client.from("bills")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()

        try await client.from("documents")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()

        try await client.from("categories")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()

        try await signOut()
    }

}
