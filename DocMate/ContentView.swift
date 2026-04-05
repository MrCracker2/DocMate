//
//  ContentView.swift
//  DocMateDummy
//
//  Created by Naman Yadav on 23/03/26.
//

import SwiftUI

private enum AddAction { case scan, photo }

struct ContentView: View {

    @Environment(AppViewModel.self) var viewModel
    
    var body: some View {

        TabView() {

            // MARK: - Home
            NavigationStack {
                HomeView()
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
}
