//
//  NewCategorySheet.swift
//  DocMateDummy
//
//  Created by Shashwat kumar on 31/03/26.
//

import SwiftUI

// MARK: - New Category Sheet
struct NewCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var categoryName  : String = ""
    @State private var selectedSymbol: String = "folder"

    let onAdd: (String, String) -> Void  // name, sfSymbol

    private let symbols = [
        "folder", "doc", "tray", "archivebox",
        "briefcase", "house", "heart", "star",
        "cart", "creditcard", "car", "airplane",
        "stethoscope", "graduationcap", "book", "camera"
    ]
    private let columns = Array(repeating: GridItem(.flexible()), count: 4)

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {

                // Name Field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Folder Name")
                        .font(.caption).foregroundStyle(.secondary)
                    TextField("e.g. Medical, Travel...", text: $categoryName)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal)

                // Icon Picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("Choose Icon")
                        .font(.caption).foregroundStyle(.secondary)
                        .padding(.horizontal)
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(symbols, id: \.self) { symbol in
                            Button { selectedSymbol = symbol } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedSymbol == symbol ? Color.blue.opacity(0.15) : Color(.systemGray6))
                                        .overlay(RoundedRectangle(cornerRadius: 10)
                                            .stroke(selectedSymbol == symbol ? Color.blue : Color.clear, lineWidth: 1.5))
                                    Image(systemName: symbol)
                                        .font(.title2)
                                        .foregroundStyle(selectedSymbol == symbol ? .blue : .primary)
                                }
                                .frame(height: 60)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }

                // Preview
                VStack(alignment: .leading, spacing: 6) {
                    Text("Preview")
                        .font(.caption).foregroundStyle(.secondary)
                    HStack(spacing: 12) {
                        ZStack {
                            Image(systemName: "folder.fill")
                                .resizable().scaledToFit()
                                .frame(width: 50, height: 40)
                                .foregroundStyle(Color(red: 0.36, green: 0.68, blue: 0.93))
                            Image(systemName: selectedSymbol)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white).offset(y: 3)
                        }
                        Text(categoryName.isEmpty ? "Folder Name" : categoryName)
                            .font(.body.weight(.medium))
                            .foregroundStyle(categoryName.isEmpty ? .secondary : .primary)
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let name = categoryName.trimmingCharacters(in: .whitespaces)
                        guard !name.isEmpty else { return }
                        onAdd(name, selectedSymbol)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(categoryName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
