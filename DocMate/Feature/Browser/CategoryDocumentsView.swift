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

    // MARK: - Context Menu State
    @State private var showRenameAlert = false
    @State private var renameText = ""
    @State private var documentToRename: Document?
    @State private var shareItems: [Any] = []
    @State private var showShareSheet = false
    @State private var showInfoSheet = false
    @State private var infoDocument: Document?
    @State private var isPreparingShare = false

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
                                .contextMenu {
                                    contextMenuItems(for: doc)
                                } preview: {
                                    DocumentThumbnailView(document: doc)
                                        .frame(width: 200, height: 260)
                                        .padding()
                                        .background(Color(.systemBackground))
                                        .environment(viewModel)
                                }
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
                            .contextMenu {
                                contextMenuItems(for: doc)
                            } preview: {
                                HStack(spacing: 14) {
                                    Image(systemName: doc.fileTypeEnum.sfSymbol)
                                        .font(.system(size: 32))
                                        .foregroundStyle(.blue)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(doc.name)
                                            .fontWeight(.semibold)
                                        Text(formatDate(doc.createdAt))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color(.systemBackground))
                            }
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
        .overlay {
            if isPreparingShare {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.3)
                            .tint(.white)
                        Text("Preparing PDF...")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }
                    .padding(24)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
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

        // MARK: - Rename Alert
        .alert("Rename", isPresented: $showRenameAlert) {
            TextField("Document name", text: $renameText)
                .autocorrectionDisabled()
            Button("Rename") {
                if let doc = documentToRename, !renameText.isEmpty {
                    Task {
                        await viewModel.renameDocument(doc, to: renameText)
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        }

        // MARK: - Get Info Sheet
        .sheet(isPresented: $showInfoSheet) {
            if let doc = infoDocument {
                DocumentInfoSheet(document: doc)
            }
        }

        // MARK: - Share Sheet
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems)
        }
    }

    // MARK: - Share (PDF-first)
    @MainActor
    private func prepareAndShare(_ doc: Document) async {
        // Check temp cache first — avoid re-downloading
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(doc.id).pdf")

        if FileManager.default.fileExists(atPath: tempURL.path) {
            shareItems = [tempURL]
            showShareSheet = true
            return
        }

        // PDF from Supabase storage
        if doc.fileTypeEnum == .pdf, let storagePath = doc.filePath, !storagePath.isEmpty {
            isPreparingShare = true
            do {
                let data = try await SupabaseManager.shared.downloadPDF(path: storagePath)
                try data.write(to: tempURL)
                shareItems = [tempURL]
            } catch {
                print("Share PDF download error: \(error)")
                // Fallback to image if download fails
                if let img = viewModel.images(for: doc).first {
                    shareItems = [img]
                } else {
                    shareItems = [doc.name]
                }
            }
            isPreparingShare = false
            showShareSheet = true
            return
        }

        // Image document
        if let img = viewModel.images(for: doc).first {
            shareItems = [img]
            showShareSheet = true
            return
        }

        // Last fallback
        shareItems = [doc.name]
        showShareSheet = true
    }

    // MARK: - Context Menu Items
    @ViewBuilder
    func contextMenuItems(for doc: Document) -> some View {

        Button {
            Task { await prepareAndShare(doc) }
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }

        Button {
            UIPasteboard.general.string = doc.name
        } label: {
            Label("Copy", systemImage: "doc.on.doc")
        }

        Button {
            // TODO: category picker for move
        } label: {
            Label("Move", systemImage: "folder")
        }

        Divider()

        Button {
            // handled by NavigationLink on tap
        } label: {
            Label("Quick Look", systemImage: "eye")
        }

        Divider()

        Button {
            infoDocument = doc
            showInfoSheet = true
        } label: {
            Label("Get Info", systemImage: "info.circle")
        }

        Button {
            documentToRename = doc
            renameText = doc.name
            showRenameAlert = true
        } label: {
            Label("Rename", systemImage: "pencil")
        }

        Button {
            Task {
                await viewModel.duplicateDocument(doc)
            }
        } label: {
            Label("Duplicate", systemImage: "plus.square.on.square")
        }

        Button {
            Task {
                await viewModel.togglePin(doc)
            }
        } label: {
            Label(
                doc.isPinned ? "Unpin" : "Pin",
                systemImage: doc.isPinned ? "pin.fill" : "pin.slash"
            )
        }

        Divider()

        Button(role: .destructive) {
            Task {
                await viewModel.deleteDocument(doc)
            }
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}

// MARK: - Document Info Sheet
struct DocumentInfoSheet: View {

    let document: Document
    @Environment(\.dismiss) var dismiss

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Document") {
                    infoRow(label: "Name", value: document.name)
                    infoRow(label: "Type", value: document.fileTypeEnum.rawValue.uppercased())
                }
                Section("Dates") {
                    infoRow(label: "Date Added", value: formatDate(document.createdAt))
                    if let due = document.dueDate {
                        infoRow(label: "Expiry Date", value: formatDate(due))
                    }
                }
                Section("Other") {
                    infoRow(label: "Pinned", value: document.isPinned ? "Yes" : "No")
                }
            }
            .navigationTitle("Document Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.primary)
            Spacer()
            Text(value).foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
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
