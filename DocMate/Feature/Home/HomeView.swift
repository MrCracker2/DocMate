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

    // MARK: - Custom Formatters & Helpers
    static let dueFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }()

    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter
    }()
    
    static let fullDueDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }()

    func formatDueDate(_ date: Date) -> String {
        Self.dueFormatter.string(from: date).uppercased()
    }
    
    func calculateDaysLeft(to dueDate: Date) -> Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfDue = calendar.startOfDay(for: dueDate)
        let components = calendar.dateComponents([.day], from: startOfToday, to: startOfDue)
        return max(components.day ?? 0, 0)
    }
    
    func calculateProgress(from createdDate: Date, to dueDate: Date) -> Double {
        let total = dueDate.timeIntervalSince(createdDate)
        guard total > 0 else { return 1.0 }
        let elapsed = Date().timeIntervalSince(createdDate)
        return min(max(elapsed / total, 0.0), 1.0)
    }

    // MARK: UI
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    
                    if viewModel.documents.isEmpty {
                        VStack(spacing: 20) {
                            // Icon with glowing backing
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.08))
                                    .frame(width: 100, height: 100)
                                    .blur(radius: 10)
                                
                                Image(systemName: "doc.text.viewfinder")
                                    .font(.system(size: 54, weight: .light))
                                    .foregroundColor(.blue)
                            }
                            .padding(.bottom, 10)
                            
                            Text("Welcome to DocMate")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("Scan and organize all your important bills, expiries, and documents securely in one place.")
                                .font(.system(size: 15, weight: .medium))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 32)
                                .lineSpacing(4)
                            
                            Button(action: {
                                showScannerFlow = true
                            }) {
                                Text("Scan First Document")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 28)
                                    .padding(.vertical, 14)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.blue, Color(red: 0.0, green: 0.45, blue: 0.95)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(Capsule())
                                    .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 16)
                        }
                        .padding(.vertical, 40)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .shadow(color: Color.blue.opacity(0.04), radius: 16, x: 0, y: 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.65), .white.opacity(0.15), Color.blue.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .padding(.top, 80)
                    } else {
                        // MARK: Overdue Section
                        if !viewModel.overdueDocuments.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                // Header
                                Text("Overdue")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 4)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(viewModel.overdueDocuments) { doc in
                                            if let due = doc.dueDate {
                                                NavigationLink(destination: DocumentDetailView(document: doc)) {
                                                    HStack(spacing: 14) {
                                                        // White rounded squircle icon container
                                                        ZStack {
                                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                                .fill(Color.white)
                                                                .frame(width: 44, height: 44)
                                                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                                            
                                                            Image(systemName: viewModel.icon(for: doc))
                                                                .font(.system(size: 20, weight: .bold))
                                                                .foregroundColor(Color(red: 0.05, green: 0.38, blue: 0.95))
                                                        }
                                                        
                                                        VStack(alignment: .leading, spacing: 6) {
                                                            Text(doc.name)
                                                                .font(.system(size: 16, weight: .bold))
                                                                .foregroundColor(.white)
                                                                .lineLimit(1)
                                                            
                                                            HStack(spacing: 4) {
                                                                Text("Expired On · \(formatDueDate(due))")
                                                                    .font(.system(size: 8, weight: .bold))
                                                                    .tracking(0.5)
                                                                    .lineLimit(1)
                                                                    .minimumScaleFactor(0.7)
                                                            }
                                                            .foregroundColor(.white)
                                                            .padding(.horizontal, 8)
                                                            .padding(.vertical, 4)
                                                            .background(Color.white.opacity(0.16))
                                                            .clipShape(Capsule())
                                                        }
                                                        
                                                        Spacer()
                                                    }
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 16)
                                                    .frame(width: 300)
                                                    .background(
                                                        LinearGradient(
                                                            colors: [
                                                                Color(red: 0.20, green: 0.55, blue: 0.98),
                                                                Color(red: 0.10, green: 0.38, blue: 0.85)
                                                            ],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                                    .shadow(color: Color.blue.opacity(0.18), radius: 12, x: 0, y: 6)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                                                            .stroke(
                                                                LinearGradient(
                                                                    colors: [.white.opacity(0.35), .white.opacity(0.05), Color.blue.opacity(0.2)],
                                                                    startPoint: .topLeading,
                                                                    endPoint: .bottomTrailing
                                                                ),
                                                                lineWidth: 1.5
                                                            )
                                                    )
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                        
                        // MARK: Expiring Shortly Section
                        VStack(alignment: .leading, spacing: 14) {
                            // Header
                            Group {
                                if !viewModel.expiringDocuments.isEmpty {
                                    NavigationLink(destination: ExpiringShortlyView()) {
                                        HStack(spacing: 6) {
                                            Text("Expiring Shortly")
                                                .font(.system(size: 24, weight: .bold))
                                                .foregroundColor(.primary)
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    Text("Expiring Shortly")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding(.horizontal, 4)
                            
                            if viewModel.expiringDocuments.isEmpty {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(Color.blue.opacity(0.08))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: "checkmark.shield.fill")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.blue)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("All Clear")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.primary)
                                        Text("No upcoming document expiries.")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(16)
                                .background(.thinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .shadow(color: Color.blue.opacity(0.03), radius: 10, x: 0, y: 5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                                )
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(viewModel.expiringDocuments) { doc in
                                            if let due = doc.dueDate {
                                                let daysLeft = calculateDaysLeft(to: due)
                                                let progress = calculateProgress(from: doc.createdAt, to: due)
                                                
                                                NavigationLink(destination: DocumentDetailView(document: doc)) {
                                                    VStack(alignment: .leading, spacing: 12) {
                                                        HStack(spacing: 12) {
                                                            // Category Icon
                                                            ZStack {
                                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                                    .fill(
                                                                        LinearGradient(
                                                                            colors: [Color.blue, Color(red: 0.15, green: 0.45, blue: 0.9)],
                                                                            startPoint: .topLeading,
                                                                            endPoint: .bottomTrailing
                                                                        )
                                                                    )
                                                                    .frame(width: 44, height: 44)
                                                                Image(systemName: viewModel.icon(for: doc))
                                                                    .font(.system(size: 20, weight: .bold))
                                                                    .foregroundColor(.white)
                                                            }
                                                            
                                                            VStack(alignment: .leading, spacing: 3) {
                                                                Text(doc.name)
                                                                    .font(.system(size: 16, weight: .bold))
                                                                    .foregroundColor(.primary)
                                                                    .lineLimit(1)
                                                                
                                                                Text("Added \(Self.shortDateFormatter.string(from: doc.createdAt))")
                                                                    .font(.system(size: 12))
                                                                    .foregroundColor(.secondary)
                                                            }
                                                            
                                                            Spacer()
                                                        }
                                                        
                                                        HStack {
                                                            HStack(spacing: 4) {
                                                                Image(systemName: "calendar")
                                                                    .font(.system(size: 11))
                                                                    .foregroundColor(.blue)
                                                                Text("Due \(Self.fullDueDateFormatter.string(from: due))")
                                                                    .font(.system(size: 12, weight: .bold))
                                                                    .foregroundColor(.secondary)
                                                            }
                                                            
                                                            Spacer()
                                                            
                                                            // Badge count
                                                            Text("\(daysLeft)d left")
                                                                .font(.system(size: 10, weight: .bold))
                                                                .foregroundColor(.white)
                                                                .padding(.horizontal, 8)
                                                                .padding(.vertical, 4)
                                                                .background(
                                                                    LinearGradient(
                                                                        colors: [Color.blue, Color(red: 0.15, green: 0.45, blue: 0.9)],
                                                                        startPoint: .topLeading,
                                                                        endPoint: .bottomTrailing
                                                                    )
                                                                )
                                                                .clipShape(Capsule())
                                                        }
                                                        .padding(.top, 4)
                                                    }
                                                    .padding(14)
                                                    .frame(width: 300)
                                                    .background(
                                                        ZStack {
                                                            Color(.secondarySystemGroupedBackground)
                                                            LinearGradient(
                                                                colors: [Color.blue.opacity(0.14), Color.blue.opacity(0.04)],
                                                                startPoint: .topLeading,
                                                                endPoint: .bottomTrailing
                                                            )
                                                        }
                                                    )
                                                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                                    .shadow(color: Color.blue.opacity(0.06), radius: 10, x: 0, y: 5)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                                                            .stroke(Color.blue.opacity(0.24), lineWidth: 1.5)
                                                    )
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                        
                        // MARK: Pinned Section
                        VStack(alignment: .leading, spacing: 14) {
                            // Header
                            Group {
                                if !viewModel.pinnedDocuments.isEmpty {
                                    NavigationLink(destination: PinnedView()) {
                                        HStack(spacing: 6) {
                                            Text("Pinned")
                                                .font(.system(size: 24, weight: .bold))
                                                .foregroundColor(.primary)
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    Text("Pinned")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding(.horizontal, 4)
                            
                            if viewModel.pinnedDocuments.isEmpty {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 8) {
                                        Image(systemName: "pin.slash.fill")
                                            .font(.system(size: 28))
                                            .foregroundColor(.secondary.opacity(0.6))
                                        Text("No Pinned Documents")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 24)
                                    Spacer()
                                }
                                .background(.thinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                                )
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(Array(viewModel.pinnedDocuments.prefix(5))) { doc in
                                            NavigationLink(destination: DocumentDetailView(document: doc)) {
                                                VStack(spacing: 8) {
                                                    ZStack {
                                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                            .fill(
                                                                LinearGradient(
                                                                    colors: [Color.blue, Color(red: 0.15, green: 0.45, blue: 0.9)],
                                                                    startPoint: .topLeading,
                                                                    endPoint: .bottomTrailing
                                                                )
                                                            )
                                                            .frame(width: 60, height: 60)
                                                            .shadow(color: Color.blue.opacity(0.12), radius: 8, x: 0, y: 4)
                                                        
                                                        Image(systemName: viewModel.icon(for: doc))
                                                            .font(.system(size: 24, weight: .semibold))
                                                            .foregroundColor(.white)
                                                    }
                                                    
                                                    Text(doc.name)
                                                        .font(.system(size: 12, weight: .bold))
                                                        .foregroundColor(.primary)
                                                        .lineLimit(1)
                                                        .frame(width: 76)
                                                }
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                        
                        // MARK: Recently Saved Section
                        VStack(alignment: .leading, spacing: 14) {
                            // Header
                            Group {
                                if viewModel.recentDocuments.count > 3 {
                                    NavigationLink(destination: RecentlySavedView()) {
                                        HStack(spacing: 6) {
                                            Text("Recently Saved")
                                                .font(.system(size: 24, weight: .bold))
                                                .foregroundColor(.primary)
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    Text("Recently Saved")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding(.horizontal, 4)
                            
                            VStack(spacing: 12) {
                                ForEach(Array(viewModel.recentDocuments.prefix(3))) { doc in
                                    NavigationLink(destination: DocumentDetailView(document: doc)) {
                                        HStack(spacing: 14) {
                                            // Document category thumbnail icon
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [Color.blue, Color(red: 0.15, green: 0.45, blue: 0.9)],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                    .frame(width: 44, height: 44)
                                                Image(systemName: viewModel.icon(for: doc))
                                                    .font(.system(size: 18, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(doc.name)
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(.primary)
                                                    .lineLimit(1)
                                                Text("Added \(Self.shortDateFormatter.string(from: doc.createdAt))")
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                .fill(Color(.secondarySystemGroupedBackground))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Color.blue.opacity(0.12), Color.clear],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [Color.blue.opacity(0.22), Color.blue.opacity(0.12)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 1
                                                )
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
