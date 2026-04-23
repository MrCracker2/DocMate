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
    
    func checkSession() async {
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
