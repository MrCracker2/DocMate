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
    
    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(
            email: email,
            password: password
        )
    }
    
    func signUp(email: String, password: String) async throws {
        try await client.auth.signUp(
            email: email,
            password: password
        )
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    func currentSession() async throws -> Session? {
        try await client.auth.session
    }
}
