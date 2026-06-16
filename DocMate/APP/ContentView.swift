//
//  ContentView.swift
//  DocMate
//
//  Created by Naman Yadav on 23/03/26.
//

import SwiftUI
struct ContentView: View {

    @Environment(AppViewModel.self)  var viewModel
    @Environment(AuthViewModel.self) var authVM

    
    var body: some View {

        TabView() {

            // MARK: - Home
            NavigationStack {
                HomeView()
                    .environment(viewModel)
                    .environment(authVM)
            }
            .tabItem { Label("Home", systemImage: "house") }
           
            // MARK: - Browse
            NavigationStack {
                BrowseView()
            }
            .tabItem { Label("Browse", systemImage: "folder") }

        }
        .task {
            await viewModel.fetchAll()
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            ),
            presenting: viewModel.errorMessage
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }
}

#Preview {
    ContentView()
        .environment(AppViewModel())
        .environment(AuthViewModel())  
}
