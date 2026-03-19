//
//  CategoryDocumentsView.swift
//  DocMate
//
//  Created by Naman Yadav on 18/03/26.
//

import SwiftUI

struct CategoryDocumentsView: View {

    @Environment(AppViewModel.self) var viewModel
    let category: Category

    @State private var searchText = ""
    @State private var isGridView = true

    
    var documents: [Document] {
        let base = viewModel.documents(for: category)
        guard !searchText.isEmpty else { return base }
        return base.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var filteredDocs: [Document] {
        viewModel.documents.filter {
            $0.categoryId == category.id
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack() {

            // MARK: Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search Document", text: $searchText)
                    .autocorrectionDisabled()

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 16)

            // MARK: Content
            if documents.isEmpty {
                Spacer()

                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary)

                    Text("No documents in \(category.name)")
                        .foregroundStyle(.secondary)
                }

                Spacer()
            } else {
                if isGridView{
                    ScrollView{
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(filteredDocs) { doc in
                                NavigationLink(destination: DocumentDetailView(document: doc)) {
                                    DocumentThumbnailView(document: doc)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom , 30)
                    }
                }else{
                    List{
                        ForEach(filteredDocs) { doc in
                            NavigationLink(destination: DocumentDetailView(document:doc)){
                                HStack{
                                    Image(doc.assetName ?? "doc.text")
                                        .resizable()
                                        .frame(width: 40, height: 50)
                                    VStack(alignment:.leading){
                                        Text(doc.name)
                                        if let due = doc.dueDate {
                                            Text(formatDate(due))
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(.vertical , 6)
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.white)
                    .listStyle(.plain)
                }
            }
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        // MARK: Menu (3 dots)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {} label: {
                        Label("New folder", systemImage: "folder.badge.plus")
                    }

                    Divider()
                    Button {
                        isGridView = true
                    } label: {
                        Label("Icons", systemImage: "square.grid.2x2")
                    }

                    Button {
                        isGridView = false
                    } label: {
                        Label("List", systemImage: "list.bullet")
                    }

                    Divider()
                    Button {} label: {
                        Label("Name", systemImage: "textformat")
                    }

                    Button {
                    } label: {
                        Label("Kind", systemImage: "doc")
                    }

                    Button {
                    } label: {
                        Label("Date", systemImage: "calendar")
                    }

                    Button {
                    } label: {
                        Label("Size", systemImage: "arrow.up.and.down")
                    }

                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title3)
                }
            }
        }
    }
}
#Preview {
    
        CategoryDocumentsView(
            category: Category(name: "Vehicle", sfSymbol: "car.side.fill",
                               fixedId: AppViewModel.vehicleId)
        )
        .environment(AppViewModel())
    
}
