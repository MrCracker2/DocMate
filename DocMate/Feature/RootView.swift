//
//  RootView.swift
//  DocMate
//
//  Created by Shashwat kumar on 23/04/26.
//

import Foundation
import SwiftUI

struct RootView: View {
    
    @Environment(AuthViewModel.self) var authVM
    
    var body: some View {
        Group {
            if authVM.isLoading {
                ProgressView()
            } else if authVM.isLoggedIn {
                ContentView()
            } else {
                LoginView()
            }
        }
        .task {
            await authVM.checkSession()
        }
    }
}
