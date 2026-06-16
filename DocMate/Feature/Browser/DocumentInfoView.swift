//
//  DocumentInfoView.swift
//  DocMate
//
//  Created by Naman Yadav on 27/04/26.
//

import SwiftUI

struct DocumentInfoView: View {

    @Environment(\.dismiss) var dismiss
    @Environment(AppViewModel.self) var viewModel
    let document: Document

    var body: some View {
        NavigationStack {
            List {
                row("Name", document.name)
                row("Category", viewModel.categories.first { $0.id == document.categoryId }?.name ?? "Unknown")
                row("Added", formatted(document.createdAt))

                if let due = document.dueDate {
                    row("Expires", formatted(due))
                }

                row("Pinned", document.isPinned ? "Yes" : "No")
                row("Type", document.fileTypeEnum.rawValue.uppercased())

                if let size = fileSizeText {
                    row("Size", size)
                }
            }
            .navigationTitle("Document Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }

    func formatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    /// Storage taken by the document, shown in KB/MB (auto-selected).
    /// Prefers the cached PDF on disk; falls back to in-memory images.
    private var fileSizeText: String? {
        let fileManager = FileManager.default
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let cachedURL = cacheDir
            .appendingPathComponent("\(document.id.uuidString.lowercased()).pdf")

        if let attrs = try? fileManager.attributesOfItem(atPath: cachedURL.path),
           let size = attrs[.size] as? Int64, size > 0 {
            return formattedSize(size)
        }

        // Fallback: estimate from the in-memory images for this document.
        let images = viewModel.images(for: document)
        let bytes = images.reduce(0) { $0 + ($1.jpegData(compressionQuality: 0.9)?.count ?? 0) }
        if bytes > 0 {
            return formattedSize(Int64(bytes))
        }

        return nil
    }

    private func formattedSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
