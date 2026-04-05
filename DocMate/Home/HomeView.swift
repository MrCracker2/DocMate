//
//  HomeView.swift
//  DocMateDummy
//
//  Created by Naman Yadav on 23/03/26.
//

import SwiftUI

struct HomeView: View {

    @Environment(AppViewModel.self) var viewModel
    @State private var showProfileView: Bool = false
    @State private var showScannerFlow: Bool = false
    @State private var showPhotoPicker: Bool = false
    @State private var pendingImages: [UIImage] = []
    @State private var showPhotoSaveSheet: Bool = false

    // MARK: Grid Layouts
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    let rows = [
        GridItem(.flexible())
    ]

    // MARK: Date Formatter
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    func formatDate(_ date: Date) -> String {
        Self.formatter.string(from: date)
    }

    // MARK: UI
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {

                // MARK: Due Soon
                Text("Due Soon")
                    .font(.title3)
                    .fontWeight(.bold)

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: rows, spacing: 16) {
                        ForEach(viewModel.expiringDocuments) { doc in
                            if let due = doc.dueDate {
                                NavigationLink(destination: DocumentDetailView(document: doc)) {
                                    DocumentCard(
                                        icon: viewModel.icon(for: doc),
                                        title: doc.name,
                                        dueDate: formatDate(due)
                                    )
                                    .frame(width: 160)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // MARK: Your Bills
                if !viewModel.inFetch.isEmpty {
                    YourBillsSection(
                        bills: viewModel.inFetch.filter { $0.inFetchCatgogry == .bill }
                    )
                }

                // MARK: Recently Saved
                HStack {
                    Text("Recently Saved")
                        .font(.title3)
                        .fontWeight(.bold)

                    if viewModel.recentDocuments.count > 4 {
                        NavigationLink(destination: RecentlySavedView()) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Array(viewModel.recentDocuments.prefix(4))) { doc in
                        NavigationLink(destination: DocumentDetailView(document: doc)) {
                            DocumentCard(
                                icon: viewModel.icon(for: doc),
                                title: doc.name
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                // MARK: Pinned Documents
                HStack {
                    Text("Pinned Documents")
                        .font(.title3)
                        .fontWeight(.bold)

                    if viewModel.pinnedDocuments.count > 5 {
                        NavigationLink(destination: PinnedView()) {
                            Image(systemName: "chevron.right")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: rows, spacing: 16) {
                        ForEach(Array(viewModel.pinnedDocuments.prefix(5))) { doc in
                            NavigationLink(destination: DocumentDetailView(document: doc)) {
                                DocumentCard(
                                    icon: viewModel.icon(for: doc),
                                    title: doc.name
                                )
                                .frame(width: 160)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Home")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {

                    // ✅ Opens ScannerFlowView — owns entire scan experience
                    Button {
                        showScannerFlow = true
                    } label: {
                        Label("Scan Document", systemImage: "doc.viewfinder")
                    }

                    // ✅ Opens photo picker
                    Button {
                        showPhotoPicker = true
                    } label: {
                        Label("Import Document", systemImage: "square.and.arrow.down")
                    }

                } label: {
                    Image(systemName: "plus")
                }

                Button {
                    showProfileView = true
                } label: {
                    Text(viewModel.user.initials)
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                }
            }
        }

        // MARK: - Profile
        .sheet(isPresented: $showProfileView) {
            ProfileView()
        }

        // MARK: - Scanner Flow (owns camera + review + OCR + save)
        .fullScreenCover(isPresented: $showScannerFlow) {
            ScannerFlowView()
        }

        // MARK: - Photo Picker
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPickerView { image in
                pendingImages = [image]
                showPhotoPicker = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showPhotoSaveSheet = true
                }
            }
        }

        // MARK: - Save Sheet for photo import
        .sheet(isPresented: $showPhotoSaveSheet) {
            SaveDocumentSheet(
                images: pendingImages,
                isScanned: false,
                detectedDate: nil
            )
        }
    }
}

// MARK: Preview
#Preview {
    NavigationStack {
        HomeView()
            .environment(AppViewModel())
    }
}
