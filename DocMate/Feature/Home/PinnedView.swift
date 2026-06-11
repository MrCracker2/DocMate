//
//  PinnedView.swift
//  DocMate
//
//  Created by Shashwat kumar on 19/03/26.
//

import SwiftUI

struct PinnedView: View {
    
    @Environment(AppViewModel.self) var viewModel
    
    
    var body: some View {
        ScrollView {
            HStack {
                Spacer()
                Grid(horizontalSpacing: 16, verticalSpacing: 16) {
                    let items = viewModel.pinnedDocuments
                    ForEach(0..<((items.count + 1) / 2), id: \.self) { rowIndex in
                        GridRow {
                            ForEach(0..<2) { columnIndex in
                                let index = rowIndex * 2 + columnIndex
                                if index < items.count {
                                    let doc = items[index]
                                    NavigationLink(destination: DocumentDetailView(document: doc)) {
                                        DocumentCard(
                                            icon: viewModel.icon(for: doc),
                                            title: doc.name
                                        )
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    Color.clear
                                    .frame(width: 170, height: 170)
                                }
                            }
                        }
                    }
                }
                Spacer()
            }
            .padding()
        }
        .navigationTitle("All Pinned")
    }
}

#Preview {
    PinnedView()
        .environment(AppViewModel())
}
