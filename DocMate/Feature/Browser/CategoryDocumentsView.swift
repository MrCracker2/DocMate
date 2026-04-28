//
//  CategoryDocumentsView.swift
//  DocMateDummy
//
//  Created by Naman Yadav on 23/03/26.
//
import SwiftUI

struct CategoryDocumentsView: View {

    @Environment(AppViewModel.self) var viewModel
    let category: Category
    @Binding var selectedCategoryId: UUID

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
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    var body: some View {
        VStack {
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
                if isGridView {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(documents) { doc in
                                NavigationLink(destination: DocumentDetailView(document: doc)) {
                                    DocumentThumbnailView(document: doc)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 10)
                        .padding(.bottom, 30)
                    }
                } else {
                    List {
                        ForEach(documents) { doc in
                            NavigationLink(destination: DocumentDetailView(document: doc)) {
                                HStack {
                                    if let assetName = doc.assetName,
                                       let img = UIImage(named: assetName) {
                                        Image(uiImage: img)
                                            .resizable()
                                            .frame(width: 40, height: 50)
                                    } else {
                                        Image(systemName: doc.fileTypeEnum.sfSymbol)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 40, height: 50)
                                            .foregroundStyle(.secondary)
                                    }
                                    VStack(alignment: .leading) {
                                        Text(doc.name)
                                        if let due = doc.dueDate {
                                            Text(formatDate(due))
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 6)
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
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search Document"
        )
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button { } label: {
                        Label("New folder", systemImage: "folder.badge.plus")
                    }
                    Divider()
                    Button { isGridView = true } label: {
                        Label("Icons", systemImage: "square.grid.2x2")
                    }
                    Button { isGridView = false } label: {
                        Label("List", systemImage: "list.bullet")
                    }
                    Divider()
                    Button { } label: { Label("Name", systemImage: "textformat") }
                    Button { } label: { Label("Kind", systemImage: "doc") }
                    Button { } label: { Label("Date", systemImage: "calendar") }
                    Button { } label: { Label("Size", systemImage: "arrow.up.and.down") }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title3)
                }
            }
        }
        .onAppear {
            if selectedCategoryId != category.id {
                selectedCategoryId = category.id
            }
        }
    }
}

#Preview {
    NavigationStack {
        CategoryDocumentsView(
            category: Category(
                name: "Demo",
                sfSymbol: "folder"
            ),
            selectedCategoryId: .constant(UUID())
        )
        .environment(AppViewModel())
    }
}
