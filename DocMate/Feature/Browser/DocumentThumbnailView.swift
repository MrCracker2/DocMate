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
                let h = w * 1.3 // portrait ratio

                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6))
                        .frame(width: w, height: h)

                    thumbnailContent
                        .frame(width: w, height: h)
                        .clipped() // ✅ scaledToFill overflow rokta hai
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
                }
                .frame(width: w, height: h)
            }
            .aspectRatio(1/1.3, contentMode: .fit)

            // MARK: Name + Date
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

    // MARK: Thumbnail Content
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

    // MARK: Async thumbnail load
    private func loadThumbnail() {
        if let cached = viewModel.images(for: document).first {
            thumbnail = cached
            return
        }
        guard let path = document.filePath, !isLoading else { return }

        isLoading = true
        Task {
            defer { isLoading = false }
            guard let data = try? await SupabaseManager.shared.downloadPDF(path: path),
                  let pdfDoc = PDFDocument(data: data),
                  let page = pdfDoc.page(at: 0) else { return }

            let pageRect = page.bounds(for: .mediaBox)
            let scale: CGFloat = 2.0
            let size = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)

            let renderer = UIGraphicsImageRenderer(size: size)
            let img = renderer.image { ctx in
                UIColor.white.set()
                ctx.fill(CGRect(origin: .zero, size: size))
                ctx.cgContext.translateBy(x: 0, y: size.height)
                ctx.cgContext.scaleBy(x: scale, y: -scale)
                page.draw(with: .mediaBox, to: ctx.cgContext)
            }

            await MainActor.run {
                thumbnail = img
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
