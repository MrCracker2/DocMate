import SwiftUI
import PDFKit

struct DocumentDetailView: View {

    @Environment(AppViewModel.self) var viewModel
    let document: Document

    @State private var showShareSheet    = false
    @State private var showDeleteConfirm = false

    // MARK: Category Name
    var categoryName: String {
        viewModel.categories.first { $0.id == document.categoryId }?.name ?? "Unknown"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {

                // MARK: Preview
                inlinePreview
                    .padding(.top)

                // MARK: Info Section
                VStack(alignment: .leading, spacing: 12) {
                    infoRow("Category", categoryName)
                    infoRow("Added", formatted(document.createdAt))

                    if let due = document.dueDate {
                        infoRow("Expires", formatted(due))
                    }

                    infoRow("Pinned", document.isPinned ? "Yes" : "No")
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                Spacer(minLength: 80)
            }
        }
        .navigationTitle(document.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)

        // MARK: 3 Dot Menu
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showShareSheet = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        viewModel.togglePin(document)
                    } label: {
                        Label(
                            document.isPinned ? "Unpin" : "Pin",
                            systemImage: document.isPinned ? "pin.slash" : "pin"
                        )
                    }

                    Divider()

                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }

        // MARK: Bottom Bar
        .safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()

                Button { showShareSheet = true } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }

                Spacer()

                Button { viewModel.togglePin(document) } label: {
                    Image(systemName: document.isPinned ? "pin.slash.fill" : "pin.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }

                Spacer()

                Button { } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }

                Spacer()

                Button { } label: {
                    Image(systemName: "info.circle")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }

                Spacer()

                Button { showDeleteConfirm = true } label: {
                    Image(systemName: "trash")
                        .font(.title2)
                        .foregroundStyle(.red)
                }

                Spacer()
            }
            .padding()
            .background(.regularMaterial)
        }

        // MARK: Share Sheet (FIXED)
        .sheet(isPresented: $showShareSheet) {
            if let firstImage = viewModel.images(for: document).first {
                ShareSheet(items: [firstImage])
            } else {
                ShareSheet(items: [document.name])
            }
        }

        // MARK: Delete Confirmation
        .confirmationDialog(
            "Delete \"\(document.name)\"?",
            isPresented: $showDeleteConfirm
        ) {
            Button("Delete", role: .destructive) {
                viewModel.deleteDocument(document)
            }
        }
    }

    // MARK: IMAGE BASED PREVIEW (FIXED)
    @ViewBuilder
    private var inlinePreview: some View {
        
        if let firstImage = viewModel.images(for: document).first {
            
            Image(uiImage: firstImage)
                .resizable()
                .scaledToFit()
                .frame(height: 460)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            
        } else if let assetName = document.assetName,
                  let image = UIImage(named: assetName) {
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            
        } else {
            previewPlaceholder
                .padding(.horizontal)
        }
    }

    // MARK: Placeholder
    private var previewPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
                .frame(height: 300)

            VStack(spacing: 10) {
                Image(systemName: document.fileType.sfSymbol)
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)

                Text("No preview available")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Info Row
    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
                .frame(width: 90, alignment: .leading)
            Text(value)
            Spacer()
        }
    }

    // MARK: Date Format
    private func formatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}
