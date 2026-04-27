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
        supabaseURL: URL(string: "https://kypcyrorwmasbmlirqzh.supabase.co")!,
        supabaseKey: "sb_publishable_BvBQx5udPXJaRUTLS9vwbw_JZiX1VdX"
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
        try await client
            .from("bills")
            .select()
            .execute()
            .value
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
    /// Download a PDF from Supabase Storage
    func downloadPDF(path: String) async throws -> Data {
        try await client.storage
            .from("documents")
            .download(path: path)
    }
    
    /// Delete a PDF from Supabase Storage
    func deletePDF(path: String) async throws {
        try await client.storage
            .from("documents")
            .remove(paths: [path])
    }
}
