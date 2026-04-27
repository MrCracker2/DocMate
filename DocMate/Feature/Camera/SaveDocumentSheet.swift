//
//  SaveDocumentSheet.swift
//  DocMateDummy
//

import SwiftUI

struct SaveDocumentSheet: View {

    //  App data
    @Environment(AppViewModel.self) var appViewModel

    
    //  ADD scanner view model (for navigation)
    var viewModel: ScannerFlowViewModel

    let images: [UIImage]
    let isScanned: Bool
    var detectedDate: Date? = nil
    var onSaveComplete: (() -> Void)? = nil

    @State private var selectedCategoryId: UUID = UUID()
    @State private var hasSelectedCategory: Bool = false
    @State private var documentName: String = "Scanned Document"
    @State private var showRenameAlert: Bool = false
    
    
    @State private var isExpanded: Bool = false
    @State private var dragOffset: CGFloat = 0
    @FocusState private var isEditingName: Bool

    // MARK: - Body
    var body: some View {
        ZStack(alignment: .bottom) {

            // MARK: - BrowseView
            BrowseView(
                isSelecting: true,
                selectedCategoryId: $selectedCategoryId
            )
            .padding(.bottom, 80)
            .onChange(of: selectedCategoryId) { _, _ in
                hasSelectedCategory = true
            }

            // MARK: - Floating Bar
            floatingBar
        }
        .navigationTitle("Save Document")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {



            // MARK: - Save Button
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
                            hasSelectedCategory
                            ? Color.blue
                            : Color.gray
                        )
                        .clipShape(Capsule())
                }
                .disabled(!hasSelectedCategory)
            }
        }

        // MARK: - Rename Alert
        .alert("Rename Document", isPresented: $showRenameAlert) {
            TextField("Document name", text: $documentName)
            Button("Done", action: {})
            Button("Cancel", role: .cancel, action: {})
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
                    .frame(width: 40, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text("Save as")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(documentName)
                    .font(.headline)
                    .lineLimit(1)
            }

            Spacer()

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

        //  Glass effect
        .background(.ultraThinMaterial)

        //  Rounded card
        .clipShape(RoundedRectangle(cornerRadius: 18))

        //  Subtle border (important!)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.2))
        )

        //  Shadow (floating feel)
        .shadow(color: .black.opacity(0.1), radius: 12, y: 6)

        //  spacing from edges
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Save
    private func save() {
        Task {
            if isScanned {
                await appViewModel.addScannedDocument(
                    images: images,
                    name: documentName,
                    categoryId: selectedCategoryId,
                    dueDate: detectedDate
                )
            } else {
                await appViewModel.addPhotoDocument(
                    image: images.first!,
                    name: documentName,
                    categoryId: selectedCategoryId
                )
            }
            onSaveComplete?()
        }
    }

}
