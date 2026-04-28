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
    }
}

#Preview {
    ContentView()
        .environment(AppViewModel())
        .environment(AuthViewModel())  
}
