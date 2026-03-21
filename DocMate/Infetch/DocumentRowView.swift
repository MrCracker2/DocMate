//
//  DocumentRowView.swift
//  DocMate
//
//  Created by Shashwat kumar on 20/03/26.
//

import SwiftUI

struct DocumentRowView: View {

    var doc: Document
    var assetName: String?
    var previewText: String?
    var isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {

            // MARK: Thumbnail
            // Asset se image milti hai toh dikhao, warna SF symbol fallback
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .frame(width: 48, height: 48)
                    .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)

                if let assetName,
                   let uiImage = UIImage(named: assetName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Image(systemName: doc.fileType.sfSymbol)
                        .foregroundColor(.black)
                        .font(.title3)
                }
            }

            // MARK: Text
            VStack(alignment: .leading, spacing: 3) {
                Text(doc.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                if let previewText {
                    Text(previewText)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                } else {
                    Text("PDF Document")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            // MARK: Checkmark
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .blue : .gray.opacity(0.4))
                .font(.title3)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
        )
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
