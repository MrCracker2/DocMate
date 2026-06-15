//
//  DocMateApp.swift
//  DocMate
//
//  Created by Shashwat kumar on 19/03/26.
//

import SwiftUI
import Supabase
import SwiftData

@main
struct DocMateApp: App {
    @State var viewModel = AppViewModel()
    @State private var authVM = AuthViewModel()
    
    init() {
        SyncManager.shared.startMonitoring()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authVM)
                .environment(viewModel)
                .modelContainer(for: LocalDocument.self)
                .onOpenURL { url in

                    print("Deep Link:", url)

                    Task {
                        do {
                            try await SupabaseManager.shared.client.auth.session(from: url)

                            if url.absoluteString.contains("reset-callback") {
                                authVM.showResetPassword = true
                            }
                        } catch {
                            print("Deep Link Error:", error)
                        }
                    }
                }
        }
    }
}


