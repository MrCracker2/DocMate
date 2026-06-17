//
//  HomeView.swift
//  DocMateDummy
//
//  Created by Naman Yadav on 23/03/26.
//

import SwiftUI
import PhotosUI
struct HomeView: View {

    @Environment(AppViewModel.self)  var viewModel
    @Environment(AuthViewModel.self) var authVM
    @State private var showProfileView: Bool = false
    @State private var showScannerFlow: Bool = false
    @State private var showPhotoPicker: Bool = false
    @State private var pendingImages: [UIImage] = []
    @State private var showPhotoSaveSheet: Bool = false
    @State private var photoFlowViewModel = ScannerFlowViewModel()
    @State private var selectedItem: PhotosPickerItem?
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
                
                
                if viewModel.documents.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 44))
                            .foregroundStyle(.blue)
                        
                        Text("Welcome to DocMate")
                            .font(.title2.bold())
                        
                        Text("Scan and organize important documents securely.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        
                        Button("Scan First Document") {
                            showScannerFlow = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.top, 120)
                }
                else{


                // MARK: Overdue
                if !viewModel.overdueDocuments.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Overdue")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHGrid(rows: rows, spacing: 16) {
                                ForEach(viewModel.overdueDocuments) { doc in
                                    if let due = doc.dueDate {
                                        NavigationLink(destination: DocumentDetailView(document: doc)) {
                                            DocumentCard(
                                                icon: viewModel.icon(for: doc),
                                                title: doc.name,
                                                dateText: formatDate(due),
                                                dateLabel: "Was due",
                                                isPendingSync: doc.filePath == nil
                                            )
                                            .frame(width: 160)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                }

                // MARK: Due Soon
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Expiring Shortly")
                            .font(.title3)
                            .fontWeight(.bold)

                        if viewModel.expiringDocuments.count > 3 {
                            NavigationLink(destination: ExpiringShortlyView()) {
                                Image(systemName: "chevron.right")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHGrid(rows: rows, spacing: 16) {
                            if viewModel.expiringDocuments.isEmpty {
                                DocumentCard(
                                    icon: "checkmark.shield",
                                    title: "All Clear",
                                    dateText: "No documents",
                                    dateLabel: "Expiry"
                                )
                                .frame(width: 160)
                            } else {
                                ForEach(viewModel.expiringDocuments) { doc in
                                    if let due = doc.dueDate {
                                        NavigationLink(destination: DocumentDetailView(document: doc)) {
                                            DocumentCard(
                                                icon: viewModel.icon(for: doc),
                                                title: doc.name,
                                                dateText: formatDate(due),
                                                dateLabel: "Due",
                                                isPendingSync: doc.filePath == nil
                                            )
                                            .frame(width: 160)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // MARK: Your Bills
                if !viewModel.inFetch.isEmpty {
                    YourBillsSection(
                        bills: Array(
                            viewModel.inFetch
                                .filter { $0.dueDate > Date() }        // sirf future due dates
                                .sorted { $0.dueDate < $1.dueDate }     // sabse jaldi due pehle
                                .prefix(4)                               // sirf top 4 cards
                        )
                    )
                }
                
                // MARK: Pinned Documents
                VStack(alignment: .leading, spacing: 12) {
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
                            if viewModel.pinnedDocuments.isEmpty {
                                DocumentCard(
                                    icon: "pin.slash",
                                    title: "No Pinned Docs"
                                )
                                .frame(width: 160)
                            } else {
                                ForEach(Array(viewModel.pinnedDocuments.prefix(5))) { doc in
                                    NavigationLink(destination: DocumentDetailView(document: doc)) {
                                        DocumentCard(
                                            icon: viewModel.icon(for: doc),
                                            title: doc.name,
                                            isPendingSync: doc.filePath == nil
                                        )
                                        .frame(width: 160)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }

                // MARK: Recently Saved
                VStack(alignment: .leading, spacing: 12) {
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
                                    title: doc.name,
                                    dateText: doc.createdAt.formatted(
                                        date: .abbreviated,
                                        time: .omitted
                                    ),
                                    dateLabel: "Added",
                                    isPendingSync: doc.filePath == nil
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
            .padding()
        }
        .navigationTitle("Home")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                AnyView(
                    HomeToolbarButtons(
                        userInitials: viewModel.user.initials,
                        showScannerFlow: $showScannerFlow,
                        showPhotoPicker: $showPhotoPicker,
                        showProfileView: $showProfileView
                    )
                )
            }
            .sharedBackgroundVisibility(.hidden)
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }

            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {

                    pendingImages = [image]
                    showPhotoSaveSheet = true
                    selectedItem = nil
                }
            }
        }
        // MARK: - Profile
        .sheet(isPresented: $showProfileView) {
            ProfileView()
                .environment(viewModel)       
                .environment(authVM)
        }

        // MARK: - Scanner Flow (owns camera + review + OCR + save)
        .fullScreenCover(isPresented: $showScannerFlow) {
            ScannerFlowView()
                .environment(viewModel)
                .environment(authVM)
        }
        // MARK: - Photo Picker
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedItem,
            matching: .images
        )
//        .sheet(isPresented: $showPhotoPicker) {
//            PhotoPickerView { image in
//                pendingImages = [image]
//                showPhotoPicker = false
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                    showPhotoSaveSheet = true
//                }
//            }
//        }

        // MARK: - Save Sheet for photo import
        .sheet(isPresented: $showPhotoSaveSheet) {
            NavigationStack {
                SaveDocumentSheet(
                    viewModel: photoFlowViewModel,   //  REQUIRED
                    images: pendingImages,
                    isScanned: false,
                    detectedDate: nil,
                    onSaveComplete: {
                        showPhotoSaveSheet = false   //  close sheet
                    }
                )
            }
            .environment(viewModel)
            .environment(authVM)      
        }
    }
}

// MARK: Preview
#Preview {
    NavigationStack {
        HomeView()
            .environment(AppViewModel())
            .environment(AuthViewModel())  
    }
}

// MARK: - Home Toolbar Buttons
private struct HomeToolbarButtons: View {
    let userInitials: String
    @Binding var showScannerFlow: Bool
    @Binding var showPhotoPicker: Bool
    @Binding var showProfileView: Bool
    
    var body: some View {
        AnyView(
            HStack(spacing: 0) {
                Menu {
                    //  Opens ScannerFlowView — owns entire scan experience
                    Button {
                        showScannerFlow = true
                    } label: {
                        Label("Scan Document", systemImage: "doc.viewfinder")
                    }

                    //  Opens photo picker
                    Button {
                        showPhotoPicker = true
                    } label: {
                        Label("Import Document", systemImage: "square.and.arrow.down")
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.blue)
                        .frame(width: 40, height: 40)
                        .glassEffect(in: Circle())
                }

                Button {
                    showProfileView = true
                } label: {
                    Text(userInitials)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.blue)
                        .frame(width: 40, height: 40)
                        .glassEffect(in: Circle())
                }
            }
            .frame(width: 82, height: 40)
        )
    }
}
