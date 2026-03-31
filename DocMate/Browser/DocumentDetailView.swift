//
//  DocumentDetailView.swift
//  DocMateDummy
//
//  Created by Naman Yadav on 23/03/26.
//
import SwiftUI
import PDFKit

// MARK: - PDFKit Wrapper
struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales       = true
        pdfView.displayMode      = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor  = UIColor.systemGray6
        pdfView.document         = PDFDocument(url: url)
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document?.documentURL != url {
            uiView.document = PDFDocument(url: url)
        }
    }
}

// MARK: - Document Detail View
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
                    infoRow("Added",    formatted(document.createdAt))

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
                    Image(systemName: "square.and.arrow.up").font(.title2).foregroundStyle(.blue)
                }
                Spacer()
                Button { viewModel.togglePin(document) } label: {
                    Image(systemName: document.isPinned ? "pin.slash.fill" : "pin.fill")
                        .font(.title2).foregroundStyle(.blue)
                }
                Spacer()
                Button { } label: {
                    Image(systemName: "slider.horizontal.3").font(.title2).foregroundStyle(.blue)
                }
                Spacer()
                Button { } label: {
                    Image(systemName: "info.circle").font(.title2).foregroundStyle(.blue)
                }
                Spacer()
                Button { showDeleteConfirm = true } label: {
                    Image(systemName: "trash").font(.title2).foregroundStyle(.red)
                }
                Spacer()
            }
            .padding()
            .background(.regularMaterial)
        }

        // MARK: Share Sheet
        .sheet(isPresented: $showShareSheet) {
            if let url = document.fileURL {
                ShareSheet(items: [url])
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

    // MARK: - Inline Preview
    // Priority: 1) saved PDF on disk  2) asset image  3) placeholder
    @ViewBuilder
    private var inlinePreview: some View {
        if let fileURL = document.fileURL {
            // ✅ Scanned / Photo documents — load from saved PDF (memory safe, multi-page)
            PDFKitView(url: fileURL)
                .frame(height: 460)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

        } else if let assetName = document.assetName,
                  let image = UIImage(named: assetName) {
            // ✅ Seeded demo documents — load from asset catalog
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

        } else {
            // ✅ Fallback placeholder
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

#Preview {
    DocumentDetailView(
        document: Document(
            name: "PUC Certificate",
            dueDate: Date().addingTimeInterval(86400 * 5),
            isPinned: true,
            userId: UUID(),
            categoryId: UUID(),
            createdAt: Date(),
            assetName: "sample_puc"
        )
    )
    .environment(AppViewModel())
}
