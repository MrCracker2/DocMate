//
//  RootView.swift
//  DocMate
//
//  Created by Shashwat kumar on 23/04/26.
//

import Foundation
import SwiftUI
import SwiftData

struct RootView: View {
    
    @Environment(AuthViewModel.self) var authVM
    @Environment(AppViewModel.self) var viewModel
    @Environment(\.modelContext) private var modelContext
    
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
            viewModel.configure(context: modelContext)
            await authVM.checkSession()
        }
    }
}
