//
//  InFetchView.swift
//  DocMate
//
//  Created by Shashwat kumar on 20/03/26.
//

import SwiftUI

struct InFetchView: View {

    @Environment(AppViewModel.self) var appViewModel
    @State private var vm = InFetchViewModel()
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding = false

    var body: some View {
        switch vm.fetchState {

        case .onboarding:
            if hasSeenOnboarding {
                // Pehle dekh chuka hai — seedha fetch
                FetchingView()
                    .onAppear { vm.startFetching() }
            } else {
                // Pehli baar — FetchHomeView dikhao
                FetchHomeView {
                    hasSeenOnboarding = true
                    vm.startFetching()
                }
            }

        case .loading:
            FetchingView()

        case .results:
            FetchedDocumentsView(vm: vm)

        case .meta:
            DocumentMetaDataView(vm: vm)
        }
    }
}
