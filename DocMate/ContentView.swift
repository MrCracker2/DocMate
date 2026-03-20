//
//  ContentView.swift
//  DocMate
//
//  Created by Shashwat kumar on 19/03/26.
//
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView{
            NavigationStack {
                HomeView()
            }
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            NavigationStack {
                AddMailAccountView()
            }
            .tabItem {
                Label("Infetch", systemImage: "envelope")
                }
            NavigationStack {
                BrowseView()
            }
            .tabItem {
                    Label("Browser", systemImage: "folder")
                }
            
                
        }
    }
}

#Preview {
    ContentView()
        .environment(AppViewModel())
}
