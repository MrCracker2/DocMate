//
//  SaveDocumentSheet.swift
//  DocMate
//
//  Created by Shashwat kumar on 04/04/26.
//

//
//  SaveDocumentSheet.swift
//  DocMateDummy
//

import SwiftUI

struct SaveDocumentSheet: View {

    @Environment(AppViewModel.self) var viewModel
    @Environment(\.dismiss) var dismiss

    let images: [UIImage]
    let isScanned: Bool
    var detectedDate: Date? = nil
    var onSaveComplete: (() -> Void)? = nil

    @State private var selectedCategoryId: UUID = AppViewModel.otherId
    @State private var documentName: String = "Scanned Document"
    @State private var showRenameAlert: Bool = false

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {

                // MARK: - BrowseView
                BrowseView(
                    isSelecting: true,
                    selectedCategoryId: $selectedCategoryId
                )
                .padding(.bottom, 80)       // space for floating bar

                // MARK: - Floating Bottom Bar
                floatingBar
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Save Document")
            .toolbar {

                // MARK: Back chevron
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .fontWeight(.semibold)
                    }
                }

                // MARK: Ellipsis
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showRenameAlert = true
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .fontWeight(.semibold)
                    }
                }

                // MARK: Save Button (blue pill)
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        save()
                    } label: {
                        Text("Save")
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedCategoryId == AppViewModel.otherId
                                ? Color.gray
                                : Color.blue
                            )
                            .clipShape(Capsule())
                    }
                    .disabled(selectedCategoryId == AppViewModel.otherId)
                }
            }

            // MARK: - Rename Alert
            .alert("Rename Document", isPresented: $showRenameAlert) {
                TextField("Document name", text: $documentName)
                Button("Done", action: {})
                Button("Cancel", role: .cancel, action: {})
            }
        }
    }

    // MARK: - Floating Bottom Bar
    private var floatingBar: some View {
        HStack(spacing: 12) {

            // Thumbnail
            if let img = images.first {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            // Name + Category
            VStack(alignment: .leading, spacing: 2) {
                Text("Save as")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(documentName)
                    .font(.headline)
                    .lineLimit(1)

                if selectedCategoryId != AppViewModel.otherId {
                    Text(
                        viewModel.categories
                            .first(where: { $0.id == selectedCategoryId })?.name ?? ""
                    )
                    .font(.caption2)
                    .foregroundStyle(.blue)
                }
            }

            Spacer()

            // Rename button
            Button {
                showRenameAlert = true
            } label: {
                Image(systemName: "pencil.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Save
    private func save() {
        let doc = Document(
            name: documentName,
            dueDate: detectedDate,          // nil if skipped, Date if confirmed
            userId: viewModel.user.id,
            categoryId: selectedCategoryId,
            fileType: isScanned ? .image : .image
        )
        viewModel.addDocument(doc, images: images)
        dismiss()
        onSaveComplete?()
    }
}
