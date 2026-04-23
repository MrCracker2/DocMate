//
//  RecentlySavedView.swift
//  DocMate
//
//  Created by Shashwat kumar on 19/03/26.
//

import SwiftUI

struct RecentlySavedView: View {
    
    @Environment(AppViewModel.self) var viewModel
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 16) {
                
                ForEach(viewModel.recentDocuments) { doc in
                    
                    NavigationLink(destination: DocumentDetailView(document: doc)) {
                        DocumentCard(
                            icon: "doc.text",
                            title: doc.name,
                            dateText: doc.createdAt.formatted(
                                date: .abbreviated,
                                time: .omitted
                            ),
                            dateLabel: "Added"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("All Recent")
    }
}
#Preview {
    RecentlySavedView()
        .environment(AppViewModel())
}
