//
//  ExpiringShortlyView.swift
//  DocMate
//
//  Created by Shashwat kumar on 16/06/26.
//

import SwiftUI

struct ExpiringShortlyView: View {

    @Environment(AppViewModel.self) var viewModel

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 16) {

                ForEach(viewModel.expiringDocuments) { doc in
                    if let due = doc.dueDate {
                        NavigationLink(destination: DocumentDetailView(document: doc)) {
                            DocumentCard(
                                icon: viewModel.icon(for: doc),
                                title: doc.name,
                                dateText: due.formatted(date: .abbreviated, time: .omitted),
                                dateLabel: "Due",
                                isPendingSync: doc.filePath == nil
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Expiring Shortly")
    }
}

#Preview {
    ExpiringShortlyView()
        .environment(AppViewModel())
}
