//
//  InFetchView.swift
//  DocMate
//
//  Created by Shashwat kumar on 20/03/26.
//

import SwiftUI

struct InFetchView: View {
    
    @Environment(AppViewModel.self) var viewModel
    
    @State private var isFetching = false
    @State private var showDocuments = false
    @State private var selectedDocs: Set<UUID> = []
    
    var fetchedDocs: [Document] {
        Array(viewModel.documents.prefix(3))
    }
    
    var body: some View {
        
        if isFetching {
            FetchingView()
        }
        
        else if showDocuments {
            FetchedDocumentsView(
                documents: fetchedDocs,
                selectedDocs: $selectedDocs
            )
        }
        
        else {
            FetchButtonView {
                isFetching = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isFetching = false
                    showDocuments = true
                }
            }
        }
    }
}
#Preview {
    InFetchView()
        .environment(AppViewModel())
}
