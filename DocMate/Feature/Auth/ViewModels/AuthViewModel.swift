//
//  AuthViewModel.swift
//  DocMate
//
//  Created by Shashwat kumar on 23/04/26.
//

import Foundation
import SwiftUI

@Observable
class AuthViewModel {

    var isLoggedIn = false
    var isLoading = true
    private var hasCheckedSession = false
    var showResetPassword = false
    

    func checkSession() async {
        guard !hasCheckedSession else { return }
        hasCheckedSession = true

        do {
            let session = try await SupabaseManager.shared.currentSession()
            isLoggedIn = session != nil
        } catch {
            isLoggedIn = false
        }

        isLoading = false
    }

    func logout() async {
        try? await SupabaseManager.shared.signOut()
        // Gmail tokens live in the Keychain under global keys, so they would
        // otherwise survive a logout and leak into the next account that signs
        // in. Disconnect Gmail here so each DocMate user starts clean.
        GmailService.shared.signOut()
        isLoggedIn = false
    }

    /// Sign in (or sign up) via Apple ID.
    /// - Parameters:
    ///   - idToken: The raw JWT string from ASAuthorizationAppleIDCredential.
    ///   - rawNonce: The un-hashed nonce that was sent to Apple during the request.
    ///   - fullName: The user's name – Apple only provides this on the VERY FIRST sign-in.
    ///   - viewModel: The app-level view model that holds documents/bills state.
    func signInWithApple(
        idToken: String,
        rawNonce: String?,
        fullName: String?,
        viewModel: AppViewModel
    ) async throws {
        // 1. Exchange the Apple identity token for a Supabase session.
        try await SupabaseManager.shared.signInWithApple(
            idToken: idToken,
            rawNonce: rawNonce
        )

        // 2. Ensure a profile row exists; update name if Apple provided one.
        try? await SupabaseManager.shared.upsertAppleUserProfile(fullName: fullName)

        // 3. Refresh app data and mark as logged in.
        viewModel.reset()
        isLoggedIn = true
        await viewModel.fetchAll()
    }
}
