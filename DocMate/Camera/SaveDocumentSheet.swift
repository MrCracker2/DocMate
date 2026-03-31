import SwiftUI

// MARK: - Save Document Sheet (Root — folder picker)
struct SaveDocumentSheet: View {
    @Environment(AppViewModel.self) var viewModel
    @Environment(\.dismiss) private var dismiss

    let images   : [UIImage]
    let isScanned: Bool

    @State private var documentName    : String
    @State private var path            : [Category] = []
    @State private var searchText      : String = ""
    @State private var viewMode        : ViewMode = .icons
    @State private var showNewCategory : Bool = false

    init(images: [UIImage], isScanned: Bool) {
        self.images    = images
        self.isScanned = isScanned

        let name = isScanned
            ? "Scan \(Date().formatted(date: .abbreviated, time: .shortened))"
            : "Photo \(Date().formatted(date: .abbreviated, time: .shortened))"

        _documentName = State(initialValue: name)
    }

    private var filtered: [Category] {
        searchText.isEmpty
            ? viewModel.categories
            : viewModel.categories.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
    }

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack(path: $path) {

            // MARK: - Root: Folder Grid
            Group {
                if viewMode == .icons {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 24) {
                            ForEach(filtered) { category in
                                NavigationLink(value: category) {
                                    FilesStyleFolderTile(
                                        name      : category.name,
                                        sfSymbol  : category.sfSymbol,
                                        itemCount : viewModel.documentCount(for: category),
                                        isSelected: false
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 120)   // clear SaveAsBar
                    }
                } else {
                    List {
                        ForEach(filtered) { category in
                            NavigationLink(value: category) {
                                FilesStyleListRow(
                                    name      : category.name,
                                    sfSymbol  : category.sfSymbol,
                                    detail    : "\(viewModel.documentCount(for: category)) items",
                                    isSelected: false
                                )
                            }
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("DocMate")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search"
            )
            .toolbar { rootToolbar }
            .safeAreaInset(edge: .bottom) {
                SaveAsBar(thumbnail: images.first, documentName: $documentName)
            }

            // MARK: - Push destination: inside a folder
            .navigationDestination(for: Category.self) { category in
                CategorySaveView(
                    category    : category,
                    images      : images,
                    isScanned   : isScanned,
                    documentName: $documentName,
                    onSave      : { dismiss() }
                )
            }
        }
        // New Folder sheet
        .sheet(isPresented: $showNewCategory) {
            NewCategorySheet { name, symbol in
                viewModel.addCategory(name: name, sfSymbol: symbol)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Root Toolbar
    @ToolbarContentBuilder private var rootToolbar: some ToolbarContent {

        // Cancel
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
        }

        // Ellipsis menu
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button { showNewCategory = true } label: {
                    Label("New Folder", systemImage: "folder.badge.plus")
                }

                Divider()

                Button { withAnimation { viewMode = .icons } } label: {
                    Label("Icons", systemImage: viewMode == .icons ? "checkmark" : "square.grid.2x2")
                }
                Button { withAnimation { viewMode = .list } } label: {
                    Label("List", systemImage: viewMode == .list ? "checkmark" : "list.bullet")
                }

                Divider()

                Button { } label: { Label("Name", systemImage: "textformat") }
                Button { } label: { Label("Kind",  systemImage: "doc") }
                Button { } label: { Label("Date",  systemImage: "calendar") }
                Button { } label: { Label("Size",  systemImage: "arrow.up.and.down") }
            } label: {
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray3), lineWidth: 1.5)
                        .frame(width: 34, height: 34)
                    Image(systemName: "ellipsis")
                        .font(.system(size: 13, weight: .semibold))
                }
            }
        }

        // Save — disabled at root (tap a folder first)
        ToolbarItem(placement: .navigationBarTrailing) {
            Text("Save")
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.35))
                .clipShape(Capsule())
        }
    }
}
