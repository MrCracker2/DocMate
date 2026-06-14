//
//  DocumentInfoView.swift
//  DocMate
//
//  Created by Naman Yadav on 27/04/26.
//
import SwiftUI
import PDFKit

struct DocumentDetailView: View {

    @Environment(AppViewModel.self) var viewModel
    let document: Document

    @State private var showShareSheet     = false
    @State private var showDeleteConfirm  = false
    @State private var showPinLimitAlert  = false   //  limit alert
    @State private var localPDFURL: URL?            // cached PDF from Supabase
    @State private var isDownloadingPDF = false
    @State private var showInfoSheet = false
    @State private var showEditSheet = false
    @Environment(\.dismiss) var dismiss
    @State private var isDeleting = false

    // Live document — array se seedha read karo
    var liveDocument: Document {
        viewModel.documents.first { $0.id == document.id } ?? document
    }

    var categoryName: String {
        viewModel.categories.first { $0.id == document.categoryId }?.name ?? "Unknown"
    }

    // Pin toggle — return value check karke alert dikhao
    func handleTogglePin() {
        Task {
            let success = await viewModel.togglePin(document)
            if !success {
                showPinLimitAlert = true
            }
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {

                inlinePreview
                    .padding(.top)
                    .onAppear { downloadPDFIfNeeded() }

                VStack(alignment: .leading, spacing: 12) {
                    infoRow("Category", categoryName)
                    infoRow("Added", formatted(document.createdAt))

                    if let due = document.dueDate {
                        infoRow("Expires", formatted(due))
                    }

                    infoRow("Pinned", liveDocument.isPinned ? "Yes" : "No")
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                Spacer(minLength: 80)
            }
        }
        .navigationTitle(liveDocument.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)

        // MARK: 3 Dot Menu
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showShareSheet = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        handleTogglePin()
                    } label: {
                        Label(
                            liveDocument.isPinned ? "Unpin" : "Pin",
                            systemImage: liveDocument.isPinned ? "pin.slash" : "pin"
                        )
                    }
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }

        // MARK: Bottom Bar
        .safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()

                Button { showShareSheet = true } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }

                Spacer()

                Button { handleTogglePin() } label: {
                    Image(systemName: liveDocument.isPinned ? "pin.slash.fill" : "pin.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }

                Spacer()

                Button {
                    showEditSheet = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }

                Spacer()

                Button {
                    showInfoSheet = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }

                Spacer()

                Button {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .font(.title2)
                        .foregroundStyle(.red)
                }
                .disabled(isDeleting)
               

                Spacer()
            }
            .padding()
            .background(.regularMaterial)
        }

        .sheet(isPresented: $showShareSheet) {
            if let pdfURL = localPDFURL {
                ShareSheet(items: [pdfURL])
            } else if let firstImage = viewModel.images(for: document).first {
                ShareSheet(items: [firstImage])
            } else {
                ShareSheet(items: [document.name])
            }
        }
        
        .sheet(isPresented: $showEditSheet) {
            EditDocumentView(document: liveDocument)
        }
        .sheet(isPresented: $showInfoSheet) {
            DocumentInfoView(document: liveDocument)
        }
        .overlay {
            if isDeleting {
                ZStack {
                    Color.black.opacity(0.2).ignoresSafeArea()

                    ProgressView("Deleting...")
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }

        // MARK: Delete Confirmation
        .alert("Delete Document?", isPresented: $showDeleteConfirm) {

            Button("Cancel", role: .cancel) { }

            Button("Delete", role: .destructive) {
                Task {
                    isDeleting = true
                    await viewModel.deleteDocument(document)
                    isDeleting = false
                    dismiss()
                }
            }

        } message: {
            Text("Are you sure you want to delete \"\(liveDocument.name)\"? This action cannot be undone.")
        }
        
        
        //  Pin Limit Alert
        .alert("Pin Limit Reached", isPresented: $showPinLimitAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You can pin a maximum of \(AppViewModel.maxPinnedDocuments) documents. Unpin one to add another.")
        }
    }

    // MARK: DOCUMENT PREVIEW (PDF + Image)
    @ViewBuilder
    private var inlinePreview: some View {
        // 1. PDF from Supabase (downloaded and cached locally)
        if let pdfURL = localPDFURL {
            PDFKitView(url: pdfURL)
                .frame(height: 500)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

        // 2. Downloading PDF
        } else if isDownloadingPDF {
            VStack(spacing: 12) {
                ProgressView()
                Text("Loading PDF...")
                    .foregroundStyle(.secondary)
            }
            .frame(height: 300)

        // 3. In-memory image (thumbnail / old scans)
        } else if let firstImage = viewModel.images(for: document).first {
            Image(uiImage: firstImage)
                .resizable()
                .scaledToFit()
                .frame(height: 460)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

        // 4. Bundled asset image (seed data)
        } else if let assetName = document.assetName,
                  let image = UIImage(named: assetName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

        // 5. No preview
        } else {
            previewPlaceholder
                .padding(.horizontal)
        }
    }

    // MARK: Download PDF from Supabase
    private func downloadPDFIfNeeded() {
        if document.fileTypeEnum == .pdf {
            guard localPDFURL == nil else { return }
            
            let fileName = "\(document.id.uuidString.lowercased()).pdf"
            let fileManager = FileManager.default
            let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
            let cachedFileURL = cacheDir.appendingPathComponent(fileName)
            
            // 1. If PDF is cached in Caches directory, use it immediately
            if fileManager.fileExists(atPath: cachedFileURL.path) {
                localPDFURL = cachedFileURL
                return
            }
            
            // 2. If online and filePath exists, download and cache it
            if let storagePath = document.filePath, !storagePath.isEmpty {
                isDownloadingPDF = true
                Task {
                    do {
                        let data = try await SupabaseManager.shared.downloadPDF(path: storagePath)
                        try data.write(to: cachedFileURL)
                        await MainActor.run {
                            localPDFURL = cachedFileURL
                            isDownloadingPDF = false
                        }
                    } catch {
                        print("PDF download error: \(error)")
                        await MainActor.run {
                            isDownloadingPDF = false
                        }
                    }
                }
            }
        }
    }

    private var previewPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
                .frame(height: 300)

            VStack(spacing: 10) {
                Image(systemName: document.fileTypeEnum.sfSymbol)
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)

                Text("No preview available")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
                .frame(width: 90, alignment: .leading)
            Text(value)
            Spacer()
        }
    }

    private func formatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}
