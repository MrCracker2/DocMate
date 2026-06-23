//
//  DocumentThumbnailView.swift
//  DocMate
//

import SwiftUI
import PDFKit

struct DocumentThumbnailView: View {
    @Environment(AppViewModel.self) var viewModel
    let document: Document

    @State private var thumbnail: UIImage? = nil
    @State private var isLoading = false

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yyyy"
        return f.string(from: document.createdAt)
    }

    var body: some View {
        VStack(spacing: 5) {
            GeometryReader { geo in
                let w = geo.size.width
                let h = w * 1.3

                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6))
                        .frame(width: w, height: h)

                    thumbnailContent
                        .frame(width: w, height: h)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    if document.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.white)
                            .padding(4)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .padding(5)
                    }
                    
                    if document.filePath == nil {
                        Image(systemName: "arrow.clockwise.icloud.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.white)
                            .padding(4)
                            .background(Color.orange)
                            .clipShape(Circle())
                            .padding(5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }
                }
                .frame(width: w, height: h)
            }
            .aspectRatio(1/1.3, contentMode: .fit)

            VStack(spacing: 1) {
                Text(document.name)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)

                Text(formattedDate)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 2)
        }
        .onAppear { loadThumbnail() }
    }

    @ViewBuilder
    private var thumbnailContent: some View {
        if let img = thumbnail ?? viewModel.images(for: document).first {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
        } else if let assetName = document.assetName,
                  let img = UIImage(named: assetName) {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
        } else if isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 4) {
                Image(systemName: document.fileTypeEnum.sfSymbol)
                    .font(.system(size: 26))
                    .foregroundStyle(.secondary)
                Text(document.fileTypeEnum.rawValue.uppercased())
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func loadThumbnail() {
        if let cached = viewModel.images(for: document).first {
            thumbnail = cached
            return
        }

        let docIdStr = document.id.uuidString.lowercased()
        let fileManager = FileManager.default
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let pdfURL = cacheDir.appendingPathComponent("\(docIdStr).pdf")
        let thumbURL = Self.durableThumbnailURL(for: docIdStr)

        // 1. Durable on-disk thumbnail (survives Caches eviction → no re-download).
        if fileManager.fileExists(atPath: thumbURL.path),
           let img = UIImage(contentsOfFile: thumbURL.path) {
            self.thumbnail = img
            viewModel.imageStore[document.id] = [img]
            return
        }

        guard !isLoading else { return }
        isLoading = true

        Task {
            defer {
                Task { @MainActor in
                    self.isLoading = false
                }
            }

            // 2. Preferred path: download the tiny stored thumbnail (a few KB)
            //    instead of the full PDF.
            if let path = document.filePath, SyncManager.shared.isOnline {
                let thumbPath = SupabaseManager.thumbnailPath(forPDFPath: path)
                if let data = try? await SupabaseManager.shared.downloadStorageFile(path: thumbPath),
                   let img = UIImage(data: data) {
                    try? data.write(to: thumbURL)
                    await MainActor.run {
                        self.thumbnail = img
                        viewModel.imageStore[document.id] = [img]
                    }
                    return
                }
            }

            // 3. Fallback for legacy/local-only docs without a stored thumbnail:
            //    render from the PDF, cache durably, and self-heal by uploading a
            //    thumbnail so subsequent loads are cheap.
            var pdfData: Data? = nil
            if fileManager.fileExists(atPath: pdfURL.path) {
                pdfData = try? Data(contentsOf: pdfURL)
            } else if let path = document.filePath, SyncManager.shared.isOnline {
                if let downloadedData = try? await SupabaseManager.shared.downloadPDF(path: path) {
                    pdfData = downloadedData
                    try? downloadedData.write(to: pdfURL)
                }
            }

            guard let data = pdfData, let img = Self.renderFirstPage(from: data) else { return }

            if let jpeg = img.jpegData(compressionQuality: 0.7) {
                try? jpeg.write(to: thumbURL)
            }

            await MainActor.run {
                self.thumbnail = img
                viewModel.imageStore[document.id] = [img]
            }

            // Self-heal: store a thumbnail remotely so we never re-download this
            // PDF for a preview again.
            if document.filePath != nil {
                await viewModel.backfillThumbnail(for: document, image: img)
            }
        }
    }

    /// Durable thumbnail location (Application Support), so previews aren't lost
    /// when iOS purges the Caches directory.
    private static func durableThumbnailURL(for id: String) -> URL {
        let fileManager = FileManager.default
        let base = (try? fileManager.url(for: .applicationSupportDirectory,
                                         in: .userDomainMask,
                                         appropriateFor: nil,
                                         create: true))
            ?? fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("Thumbnails", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("thumb_\(id).jpg")
    }

    /// Renders page 1 of a PDF into a small preview image.
    private nonisolated static func renderFirstPage(from data: Data) -> UIImage? {
        guard let provider = CGDataProvider(data: data as CFData),
              let pdfDoc = CGPDFDocument(provider),
              let page = pdfDoc.page(at: 1) else {
            return nil
        }

        let pageRect = page.getBoxRect(.mediaBox)
        let scale: CGFloat = 0.3
        let width = max(1, Int(pageRect.width * scale))
        let height = max(1, Int(pageRect.height * scale))

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
}
// MARK: - ShareSheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
