// 3
// this screen open afther user select  folder
import SwiftUI

// MARK: - Category Save View (inside a folder while saving)
struct CategorySaveView: View {
    @Environment(AppViewModel.self) var viewModel

    let category    : Category
    let images      : [UIImage]
    let isScanned   : Bool
    @Binding var documentName: String
    var onSave      : () -> Void               // dismisses the whole sheet

    @State private var searchText       = ""
    @State private var viewMode         : ViewMode = .icons
    @State private var showNewCategory  = false

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    // Existing docs already in this folder (filtered by search)
    private var existingDocs: [Document] {
        let base = viewModel.documents(for: category)
        guard !searchText.isEmpty else { return base }
        return base.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var isSaveEnabled: Bool {
        !documentName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        Group {
            if viewMode == .icons {
                iconGrid
            } else {
                listContent
            }
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search"
        )
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) { ellipsisMenu }
            ToolbarItem(placement: .navigationBarTrailing) { saveButton }
        }
        .safeAreaInset(edge: .bottom) {
            SaveAsBar(thumbnail: images.first, documentName: $documentName)
        }
        .sheet(isPresented: $showNewCategory) {
            NewCategorySheet { name, symbol in
                viewModel.addCategory(name: name, sfSymbol: symbol)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Icon Grid
    private var iconGrid: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 20) {
                // Ghost pending tile — always first
                PendingDocumentTile(
                    image: images.first,
                    name: documentName,
                    isScanned: isScanned
                )

                // Existing documents
                ForEach(existingDocs) { doc in
                    SaveModeDocTile(document: doc)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 120)   // clear SaveAsBar
        }
    }

    // MARK: - List Content
    private var listContent: some View {
        List {
            // Ghost pending tile as first row
            PendingDocumentListRow(
                image: images.first,
                name: documentName,
                isScanned: isScanned
            )

            ForEach(existingDocs) { doc in
                SaveModeDocListRow(document: doc)
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Ellipsis Menu
    private var ellipsisMenu: some View {
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
            Button { } label: { Label("Kind", systemImage: "doc") }
            Button { } label: { Label("Date", systemImage: "calendar") }
            Button { } label: { Label("Size", systemImage: "arrow.up.and.down") }
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

    // MARK: - Save Button
    private var saveButton: some View {
        Button {
            saveAndDismiss()
        } label: {
            Text("Save")
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(isSaveEnabled ? Color.blue : Color.blue.opacity(0.35))
                .clipShape(Capsule())
        }
        .disabled(!isSaveEnabled)
    }

    // MARK: - Save Logic
    private func saveAndDismiss() {
        let name = documentName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        if isScanned {
            viewModel.addScannedDocument(images: images, name: name, categoryId: category.id)
        } else if let img = images.first {
            viewModel.addPhotoDocument(image: img, name: name, categoryId: category.id)
        }

        onSave()
    }
}

// MARK: - Ghost / Pending Tile (icon grid)
private struct PendingDocumentTile: View {
    let image    : UIImage?
    let name     : String
    let isScanned: Bool

    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yy"
        return f.string(from: Date())
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .bottomLeading) {
                // Thumbnail card
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray5))
                        .aspectRatio(0.75, contentMode: .fit)

                    if let img = image {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .opacity(0.55)
                    } else {
                        Image(systemName: isScanned ? "doc.viewfinder" : "photo")
                            .font(.system(size: 26))
                            .foregroundStyle(.secondary)
                            .opacity(0.55)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemBackground).opacity(0.25))
                )

                // Red progress dot
                Circle()
                    .fill(Color.red)
                    .frame(width: 9, height: 9)
                    .padding(5)
            }

            Text(name.isEmpty ? (isScanned ? "Scanned Document" : "Photo") : name)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundStyle(.secondary)

            Text(dateString)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .opacity(0.75)
    }
}

// MARK: - Ghost Pending List Row
private struct PendingDocumentListRow: View {
    let image    : UIImage?
    let name     : String
    let isScanned: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray5))
                    .frame(width: 40, height: 52)

                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .opacity(0.55)
                } else {
                    Image(systemName: isScanned ? "doc.viewfinder" : "photo")
                        .foregroundStyle(.secondary)
                        .opacity(0.55)
                }

                // red dot
                Circle()
                    .fill(Color.red)
                    .frame(width: 7, height: 7)
                    .offset(x: -14, y: 20)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(name.isEmpty ? (isScanned ? "Scanned Document" : "Photo") : name)
                    .font(.body)
                    .foregroundStyle(.secondary)
                Text("Pending")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .opacity(0.75)
    }
}

// MARK: - Existing Doc Tile (icon grid, save mode — non-tappable)
private struct SaveModeDocTile: View {
    @Environment(AppViewModel.self) var viewModel
    let document: Document

    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yy"
        return f.string(from: document.createdAt)
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray5))
                    .aspectRatio(0.75, contentMode: .fit)

                if let assetName = document.assetName,
                   let img = UIImage(named: assetName) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else if let firstPage = viewModel.images(for: document).first {
                    Image(uiImage: firstPage)
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Image(systemName: document.fileType.sfSymbol)
                        .font(.system(size: 26))
                        .foregroundStyle(.secondary)
                }
            }

            Text(document.name)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(dateString)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Existing Doc List Row (list mode, save mode — non-tappable)
private struct SaveModeDocListRow: View {
    @Environment(AppViewModel.self) var viewModel
    let document: Document

    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yy"
        return f.string(from: document.createdAt)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray5))
                    .frame(width: 40, height: 52)

                if let assetName = document.assetName,
                   let img = UIImage(named: assetName) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else if let firstPage = viewModel.images(for: document).first {
                    Image(uiImage: firstPage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    Image(systemName: document.fileType.sfSymbol)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(document.name)
                    .font(.body)
                    .foregroundStyle(.primary)
                Text(dateString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    }
}
