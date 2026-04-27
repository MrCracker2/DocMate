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
    @Environment(AppViewModel.self) var viewModel
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    var body: some View {
        Group {
            
            if !hasSeenOnboarding {
                OnboardingView()
                
            } else {
                
                if authVM.isLoading {
                    ProgressView()
                    
                } else if authVM.isLoggedIn {
                    ContentView()
                    
                } else {
                    LoginView()
                }
            }
        }
        .task {
            NotificationManager.shared.requestPermission()
            await authVM.checkSession()

            guard authVM.isLoggedIn else { return }

            await viewModel.seedIfNeeded()
            await viewModel.fetchAll()
        }
    }
}
