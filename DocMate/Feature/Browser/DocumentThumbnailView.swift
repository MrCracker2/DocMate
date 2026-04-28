

import SwiftUI

struct DocumentThumbnailView: View {
    @Environment(AppViewModel.self) var viewModel
    let document: Document

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yyyy"
        return f.string(from: document.createdAt)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .aspectRatio(0.75, contentMode: .fit)

                previewContent
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                if document.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .padding(6)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .padding(8)
                }
            }

            VStack(spacing: 4) {
                Text(document.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)

                Text(formattedDate)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var previewContent: some View {
        if let img = viewModel.images(for: document).first {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
        } else if let assetName = document.assetName,
                  let img = UIImage(named: assetName) {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
        } else {
            VStack(spacing: 8) {
                Image(systemName: document.fileTypeEnum.sfSymbol)
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)

                Text(document.fileTypeEnum.rawValue.uppercased())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
