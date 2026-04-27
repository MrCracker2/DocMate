//
//  DocumentInfoView.swift
//  DocMate
//
//  Created by Shashwat kumar on 27/04/26.
//

import SwiftUI

struct DocumentInfoView: View {

    @Environment(\.dismiss) var dismiss
    let document: Document

    var body: some View {
        NavigationStack {
            List {
                row("Name", document.name)
                row("Pinned", document.isPinned ? "Yes" : "No")
                row("Created", formatted(document.createdAt))

                if let due = document.dueDate {
                    row("Expiry", formatted(due))
                }

                row("Type", document.fileTypeEnum.rawValue.uppercased())
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
}
