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

    var body: some View {
        switch vm.fetchState {

        case .onboarding:
            FetchHomeView {
                vm.startFetching()
            }

        case .loading:
            FetchingView()

        case .results:
            // NavigationStack already ContentView mein hai
            // isliye directly view daal do — apna NavigationStack mat banao
            FetchedDocumentsView(vm: vm)

        case .meta:
            DocumentMetaDataView(vm: vm)
        }
    }
}
