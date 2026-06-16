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
        isLoggedIn = false
    }
}
