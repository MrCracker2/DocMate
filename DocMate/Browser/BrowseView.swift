//
//  BrowseView.swift
//  DocMate
//
//  Created by Shashwat kumar on 19/03/26.
//

import SwiftUI

struct BrowseView: View {

    @Environment(AppViewModel.self) var viewModel
    @State private var searchText: String = ""
    @State private var isGridView: Bool = true

    var filteredCategories: [Category] {
        if searchText.isEmpty {
            return viewModel.categories
        }
        return viewModel.categories.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // MARK: Categories Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Categories")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    if isGridView {
                        // MARK: Grid Layout
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(filteredCategories) { category in
                                NavigationLink(
                                    destination: CategoryDocumentsView(category: category)
                                ) {
                                    CategoryCardView(category: category)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)

                    } else {
                        // MARK: List Layout
                        VStack(spacing: 0) {
                            ForEach(filteredCategories) { category in
                                NavigationLink(
                                    destination: CategoryDocumentsView(category: category)
                                ) {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.blue.opacity(0.12))
                                                .frame(width: 40, height: 40)
                                            Image(systemName: category.sfSymbol)
                                                .font(.system(size: 18))
                                                .foregroundStyle(.blue)
                                        }

                                        Text(category.name)
                                            .font(.body)
                                            .foregroundStyle(.primary)

                                        Spacer()

                                        Text("\(viewModel.documentCount(for: category))")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)

                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal)
                                }
                                .buttonStyle(.plain)

                                if category.id != filteredCategories.last?.id {
                                    Divider()
                                        .padding(.leading, 68)
                                }
                            }
                        }
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }
                }

                // MARK: Tags Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tags")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    VStack(spacing: 0) {
                        ForEach(viewModel.tags) { tag in
                            TagRowView(tag: tag)

                            if tag.id != viewModel.tags.last?.id {
                                Divider()
                                    .padding(.leading)
                            }
                        }
                    }
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        .navigationTitle("Browse")
        .navigationBarTitleDisplayMode(.large)
        // MARK: Native Apple HIG Search Bar
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search categories"
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {

                    } label: {
                        Label("New Folder", systemImage: "folder.badge.plus")
                    }

                    Divider()

                    // MARK: View Toggle — Grid
                    Button {
                        isGridView = true
                    } label: {
                        Label("Icons", systemImage: "square.grid.2x2")
                    }

                    // MARK: View Toggle — List
                    Button {
                        isGridView = false
                    } label: {
                        Label("List", systemImage: "list.bullet")
                    }

                    Divider()

                    Button {} label: {
                        Label("Name", systemImage: "textformat")
                    }

                    Button {} label: {
                        Label("Kind", systemImage: "doc")
                    }

                    Button {} label: {
                        Label("Date", systemImage: "calendar")
                    }

                    Button {} label: {
                        Label("Size", systemImage: "arrow.up.and.down")
                    }

                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
            }
        }
    }
}

#Preview {
    
        BrowseView()
            .environment(AppViewModel())
    
}
