//
//  ContentView.swift
//  DocMate
//
//  Created by Shashwat kumar on 19/03/26.
//
import SwiftUI

struct ContentView: View {

    @Environment(AppViewModel.self) var viewModel
    @AppStorage("hasAddedMail") var hasAddedMail = false

    var body: some View {
        @Bindable var vm = viewModel

        TabView() {
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("Home", systemImage: "house") }
            

            NavigationStack {
                if hasAddedMail {
                    InFetchView()
                } else {
                    AddMailAccountView()
                }
            }
            .tabItem { Label("Infetch", systemImage: "envelope") }
            

            NavigationStack {
                BrowseView()
            }
            .tabItem { Label("Browser", systemImage: "folder") }
            
        }
    }
}

#Preview {
    ContentView()
        .environment(AppViewModel())
}
