import SwiftUI

struct BrowseView: View {

    @Environment(AppViewModel.self) var viewModel
    @State private var searchText: String = ""
    @State private var isGridView: Bool = true
    
    let isSelecting: Bool
    @Binding var selectedCategoryId: UUID
    
    init(
        isSelecting: Bool = false,
        selectedCategoryId: Binding<UUID> = .constant(UUID())
    ) {
        self.isSelecting = isSelecting
        self._selectedCategoryId = selectedCategoryId
    }

    var filteredCategories: [Category] {
        if searchText.isEmpty {
            return viewModel.categories
        }
        return viewModel.categories.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {

                // MARK: Categories Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Categories")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    if isGridView {

                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(filteredCategories) { category in
                                
                                let isSelected = selectedCategoryId == category.id
                                
                                NavigationLink {
                                    CategoryDocumentsView(
                                        category: category,
                                        selectedCategoryId: $selectedCategoryId
                                    )
                                } label: {
                                    
                                    CategoryCardView(
                                        category: category,
                                        docCount: viewModel.documentCount(for: category)
                                    )
                                    .background(
                                        isSelecting && isSelected
                                        ? Color.blue.opacity(0.15)
                                        : Color.clear
                                    )
                                    .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                                .simultaneousGesture(TapGesture().onEnded {
                                    if isSelecting {
                                        selectedCategoryId = category.id
                                    }
                                })
                            }
                        }
                        .padding(.horizontal)

                    } else {

                        VStack(spacing: 0) {
                            ForEach(filteredCategories) { category in
                                
                                let isSelected = selectedCategoryId == category.id
                                
                                NavigationLink {
                                    CategoryDocumentsView(
                                        category: category,
                                        selectedCategoryId: $selectedCategoryId
                                    )
                                } label: {
                                    
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
                                            .foregroundStyle(.primary)

                                        Spacer()

                                        Text("\(viewModel.documentCount(for: category))")
                                            .foregroundStyle(.secondary)

                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal)
                                    .background(
                                        isSelecting && isSelected
                                        ? Color.blue.opacity(0.15)
                                        : Color.clear
                                    )
                                }
                                .buttonStyle(.plain)
                                .simultaneousGesture(TapGesture().onEnded {
                                    if isSelecting {
                                        selectedCategoryId = category.id
                                    }
                                })

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
        .navigationBarTitleDisplayMode(
            isSelecting ? .inline : .large
        )
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search categories"
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { } label: {
                        Label("New Folder", systemImage: "folder.badge.plus")
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

                    Button {} label: { Label("Name", systemImage: "textformat") }
                    Button {} label: { Label("Kind", systemImage: "doc") }
                    Button {} label: { Label("Date", systemImage: "calendar") }
                    Button {} label: { Label("Size", systemImage: "arrow.up.and.down") }

                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title3)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        BrowseView(
            isSelecting: false,
            selectedCategoryId: .constant(UUID())
        )
        .environment(AppViewModel())
    }
}
