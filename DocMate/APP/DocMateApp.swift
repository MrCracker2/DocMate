//
//  DocMateApp.swift
//  DocMate
//
//  Created by Shashwat kumar on 19/03/26.
//

import SwiftUI

@main
struct DocMateApp: App {
    @State var viewModel = AppViewModel()
    @State private var authVM = AuthViewModel()
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authVM)
                .environment(viewModel)
        }
    }
}


