//
//  ContentView.swift
//  DocMate
//
//  Created by Shashwat kumar on 19/03/26.
//
import SwiftUI

struct ContentView: View {

    @Environment(AppViewModel.self) var viewModel

    @State private var selectedTab     = 0
    @State private var showScanner     = false
    @State private var showPhotoPicker = false

    var body: some View {

        TabView() {
            
            NavigationStack {
                HomeView()
            }
                .tabItem { Label("Home", systemImage: "house") }
                

            NavigationStack{ EmptyView()}
            .tabItem{
                Label("Add" , systemImage: "document.badge.plus")
                
            }

            NavigationStack { BrowseView() }
                .tabItem { Label("Browse", systemImage: "folder") }
                
        }
    }
}

#Preview {
    ContentView()
        .environment(AppViewModel())
}
