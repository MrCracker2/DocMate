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
    @State private var showQLPreview = false
    @State private var markupMode: MarkupMode?      // PencilKit editor
    @State private var showRenameAlert = false
    @State private var renameText = ""
    @State private var showExportSheet = false
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
        inlinePreview
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear { downloadPDFIfNeeded() }
            .contentShape(Rectangle())
            .onTapGesture {
                if getPreviewURL() != nil {
                    showQLPreview = true
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
                        rotateDocument(clockwise: false)
                    } label: {
                        Label("Rotate Left", systemImage: "rotate.left")
                    }

                    Button {
                        rotateDocument(clockwise: true)
                    } label: {
                        Label("Rotate Right", systemImage: "rotate.right")
                    }

                    Button {
                        renameText = liveDocument.name
                        showRenameAlert = true
                    } label: {
                        Label("Rename", systemImage: "character.cursor.ibeam")
                    }

                    Divider()

                    Button {
                        showExportSheet = true
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up.on.square")
                    }

                    Button {
                        printDocument()
                    } label: {
                        Label("Print", systemImage: "printer")
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

        // MARK: Floating Glass Toolbars (Apple Preview style — two groups)
        .overlay(alignment: .bottom) {
            HStack(spacing: 12) {

                // Group 1 — Editing tools
                glassGroup {
                    toolButton("pencil.tip.crop.circle") { markupMode = .markup }    // Markup
                    toolButton("signature")              { markupMode = .signature } // Signature
                    toolButton("crop")                   { markupMode = .crop }      // Crop
                }

                // Group 2 — Document actions
                glassGroup {
                    toolButton("info.circle")            { showInfoSheet = true }   // Info
                    toolButton("square.and.arrow.up")    { showShareSheet = true }  // Share
                    toolButton(liveDocument.isPinned ? "pin.slash" : "pin") {       // Pin
                        handleTogglePin()
                    }
                }
            }
            .padding(.bottom, 16)
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
        .fullScreenCover(isPresented: $showQLPreview) {
            if let previewURL = getPreviewURL() {
                QuickLookPreviewView(url: previewURL) { editedURL in
                    handlePreviewSave(editedURL: editedURL)
                } onDismiss: {
                    showQLPreview = false
                }
                .ignoresSafeArea()
            }
        }
        .fullScreenCover(item: $markupMode) { mode in
            if let previewURL = getPreviewURL() {
                MarkupEditorView(url: previewURL, mode: mode) { editedURL in
                    handlePreviewSave(editedURL: editedURL)
                    markupMode = nil
                } onCancel: {
                    markupMode = nil
                }
                .ignoresSafeArea()
            }
        }
        .sheet(isPresented: $showExportSheet) {
            if let image = currentDocumentImage() {
                ExportDocumentView(image: image, fileName: liveDocument.name)
            } else {
                Text("Nothing to export").padding()
            }
        }
        .alert("Rename Document", isPresented: $showRenameAlert) {
            TextField("Name", text: $renameText)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                let name = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { return }
                Task { await viewModel.renameDocument(document, to: name) }
            }
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

    // MARK: - Glass Toolbar Helpers

    /// A frosted-glass capsule that wraps a group of tool buttons.
    @ViewBuilder
    private func glassGroup<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        HStack(spacing: 22) {
            content()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.primary.opacity(0.15), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    }

    /// A single icon button used inside a glass group.
    private func toolButton(_ systemName: String,
                            tint: Color = .primary,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title2)
                .foregroundStyle(tint)
        }
    }

    // MARK: DOCUMENT PREVIEW (PDF + Image)
    @ViewBuilder
    private var inlinePreview: some View {
        // 1. PDF from Supabase (downloaded and cached locally)
        if let pdfURL = localPDFURL {
            PDFKitView(url: pdfURL)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(edges: .bottom)

        // 2. Downloading PDF
        } else if isDownloadingPDF {
            VStack(spacing: 12) {
                ProgressView()
                Text("Loading PDF...")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        // 3. In-memory image (thumbnail / old scans)
        } else if let firstImage = viewModel.images(for: document).first {
            Image(uiImage: firstImage)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        // 4. Bundled asset image (seed data)
        } else if let assetName = document.assetName,
                  let image = UIImage(named: assetName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        // 5. No preview
        } else {
            previewPlaceholder
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    private func formatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    // MARK: - Quick Look Helpers
    private func getPreviewURL() -> URL? {
        if let pdfURL = localPDFURL {
            return pdfURL
        }
        
        if let image = viewModel.images(for: document).first {
            let fileName = "\(document.id.uuidString.lowercased()).jpg"
            let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            let fileURL = cacheDir.appendingPathComponent(fileName)
            if let data = image.jpegData(compressionQuality: 1.0) {
                try? data.write(to: fileURL)
                return fileURL
            }
        }
        
        if let assetName = document.assetName, let image = UIImage(named: assetName) {
            let fileName = "\(document.id.uuidString.lowercased()).jpg"
            let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            let fileURL = cacheDir.appendingPathComponent(fileName)
            if let data = image.jpegData(compressionQuality: 1.0) {
                try? data.write(to: fileURL)
                return fileURL
            }
        }
        
        return nil
    }

    private func generateThumbnail(from pdfURL: URL) -> UIImage? {
        guard let provider = CGDataProvider(url: pdfURL as CFURL),
              let pdf = CGPDFDocument(provider),
              let page = pdf.page(at: 1) else {
            return nil
        }
        
        let pageRect = page.getBoxRect(.mediaBox)
        let scale: CGFloat = 0.4
        let width = Int(pageRect.width * scale)
        let height = Int(pageRect.height * scale)
        
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: nil,
                  width: width,
                  height: height,
                  bitsPerComponent: 8,
                  bytesPerRow: 0,
                  space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            return nil
        }
        
        context.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: scale, y: -scale)
        
        context.drawPDFPage(page)
        
        guard let cgImage = context.makeImage() else { return nil }
        return UIImage(cgImage: cgImage)
    }

    // MARK: - Menu Actions (rotate / print / export source)

    /// The current document rendered as an image, capped to keep memory bounded.
    private func currentDocumentImage() -> UIImage? {
        let maxDim: CGFloat = 2200
        if let url = localPDFURL, let doc = PDFDocument(url: url), let page = doc.page(at: 0) {
            let b = page.bounds(for: .mediaBox)
            let longest = max(b.width, b.height)
            let factor = min(2.0, maxDim / max(longest, 1))
            let target = CGSize(width: b.width * factor, height: b.height * factor)
            return page.thumbnail(of: target, for: .mediaBox)
        }
        if let image = viewModel.images(for: document).first { return cappedImage(image, maxDim: maxDim) }
        if let name = document.assetName, let image = UIImage(named: name) {
            return cappedImage(image, maxDim: maxDim)
        }
        return nil
    }

    private func cappedImage(_ image: UIImage, maxDim: CGFloat) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > maxDim else { return image }
        let factor = maxDim / longest
        let newSize = CGSize(width: image.size.width * factor, height: image.size.height * factor)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private func rotateDocument(clockwise: Bool) {
        guard let image = currentDocumentImage(),
              let rotated = image.rotated(clockwise: clockwise) else { return }
        let pdfData = PDFConverter.makePDF(from: [rotated])
        refreshInlinePreview(with: pdfData)
        Task {
            await viewModel.updateDocumentFile(document: document, pdfData: pdfData, newThumbnail: rotated)
        }
    }

    private func printDocument() {
        guard let url = getPreviewURL() else { return }
        let controller = UIPrintInteractionController.shared
        let info = UIPrintInfo(dictionary: nil)
        info.outputType = .general
        info.jobName = liveDocument.name
        controller.printInfo = info
        if let data = try? Data(contentsOf: url) {
            controller.printingItem = data
        } else {
            controller.printingItem = url
        }
        controller.present(animated: true)
    }

    private func handlePreviewSave(editedURL: URL) {
        do {
            let data = try Data(contentsOf: editedURL)
            let pdfData: Data
            let thumbnail: UIImage?

            if document.fileTypeEnum == .pdf || editedURL.pathExtension.lowercased() == "pdf" {
                pdfData = data
                thumbnail = generateThumbnail(from: editedURL)
            } else if let image = UIImage(contentsOfFile: editedURL.path) {
                pdfData = PDFConverter.makePDF(from: [image])
                thumbnail = image
            } else {
                return
            }

            // 1. Update the local cache + on-screen preview immediately.
            refreshInlinePreview(with: pdfData)

            // 2. Then push to the backend in the background.
            Task {
                await viewModel.updateDocumentFile(document: document, pdfData: pdfData, newThumbnail: thumbnail)
            }
        } catch {
            print("Failed to save edited contents: \(error)")
        }
    }

    /// Writes the edited PDF to the local cache and forces the inline preview to
    /// rebuild, so the change is visible immediately (not only after reopening).
    private func refreshInlinePreview(with pdfData: Data) {
        let fileName = "\(document.id.uuidString.lowercased()).pdf"
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let cachedURL = cacheDir.appendingPathComponent(fileName)
        try? pdfData.write(to: cachedURL)

        // Drop then re-assign on the next runloop so the PDFKitView is recreated
        // with the new file contents (same URL alone wouldn't trigger a reload).
        localPDFURL = nil
        DispatchQueue.main.async {
            localPDFURL = cachedURL
        }
    }
}
