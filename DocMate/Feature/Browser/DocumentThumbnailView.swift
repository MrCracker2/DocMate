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
        let thumbURL = cacheDir.appendingPathComponent("thumb_\(docIdStr).png")
        
        // 1. Try to load from disk cache synchronously
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
            
            var pdfData: Data? = nil
            
            // 2. Resolve PDF data (from local cache or remote download)
            if fileManager.fileExists(atPath: pdfURL.path) {
                pdfData = try? Data(contentsOf: pdfURL)
            } else if let path = document.filePath {
                if SyncManager.shared.isOnline {
                    if let downloadedData = try? await SupabaseManager.shared.downloadPDF(path: path) {
                        pdfData = downloadedData
                        try? downloadedData.write(to: pdfURL)
                    }
                }
            }
            
            // 3. Render thumbnail using Core Graphics (nonisolated background thread)
            guard let data = pdfData,
                  let provider = CGDataProvider(data: data as CFData),
                  let pdfDoc = CGPDFDocument(provider),
                  let page = pdfDoc.page(at: 1) else {
                return
            }
            
            let pageRect = page.getBoxRect(.mediaBox)
            let scale: CGFloat = 0.3
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
                return
            }
            
            context.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            context.translateBy(x: 0, y: CGFloat(height))
            context.scaleBy(x: scale, y: -scale)
            context.drawPDFPage(page)
            
            guard let cgImage = context.makeImage() else { return }
            let img = UIImage(cgImage: cgImage)
            
            // 4. Save to disk cache
            if let pngData = img.pngData() {
                try? pngData.write(to: thumbURL)
            }
            
            // 5. Update UI on MainActor
            await MainActor.run {
                self.thumbnail = img
                viewModel.imageStore[document.id] = [img]
            }
        }
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
