//
//  DocumentThumbnailView.swift
//  DocMate
//
//  Created by Naman Yadav on 18/03/26.
//

import SwiftUI


struct DocumentThumbnailView: View {
    let document: Document

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "M/d/yyyy"
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

            Text(formattedDate)
                .font(.caption2)
                .foregroundStyle(.secondary)
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
