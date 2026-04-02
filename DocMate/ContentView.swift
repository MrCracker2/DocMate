//
//  ContentView.swift
//  DocMateDummy
//
//  Created by Naman Yadav on 23/03/26.
//

import SwiftUI

private enum AddAction { case scan, photo }

struct ContentView: View {

    @Environment(AppViewModel.self) var viewModel

    @State private var selectedTab     = 0
    @State private var previousTab     = 0
    @State private var showAddMenu     = false
    @State private var showScanner     = false
    @State private var showPhotoPicker = false
    @State private var showSaveSheet   = false

    @State private var pendingImages: [UIImage] = []
    @State private var pendingIsScanned = true
    @State private var pendingAction: AddAction? = nil //Stores what user selected in menu

    var body: some View {

        TabView(selection: $selectedTab) {

            // MARK: - Home
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("Home", systemImage: "house") }
            .tag(0)

            // MARK: - Add (action button — no content)
            Color.clear
                .tabItem {
                    Label("Add", systemImage: "document.badge.plus")
                }
                .tag(1)
            
            

            // MARK: - Browse
            NavigationStack {
                BrowseView()
            }
            .tabItem { Label("Browse", systemImage: "folder") }
            .tag(2)
        }
        // Intercept tap: snap back, show bottom menu
        .onChange(of: selectedTab) { _, newValue in
            if newValue == 1 {
                selectedTab = previousTab
                showAddMenu = true
            } else {
                previousTab = newValue
            }
        }
        

        // MARK: - Bottom Add Menu
        .sheet(isPresented: $showAddMenu) {
            AddDocumentMenuView(
                onScan: {
                    pendingAction = .scan
                    showAddMenu = false
                },
                onImport: {
                    pendingAction = .photo
                    showAddMenu = false
                }
            )
            .presentationDetents([.height(200)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(20)
        }
        // After menu closes, launch the chosen action
        .onChange(of: showAddMenu) { _, isShowing in
            guard !isShowing, let action = pendingAction else { return }
            pendingAction = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                switch action {
                case .scan:  showScanner = true
                case .photo: showPhotoPicker = true
                }
            }
        }

        // MARK: - Scanner (full screen, VisionKit)
        .fullScreenCover(
            isPresented: $showScanner,
            onDismiss: {
                // Only open save sheet if images were actually captured
                guard !pendingImages.isEmpty else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    showSaveSheet = true
                }
            }
        ) {
            DocumentScannerView { images in
                pendingImages    = images
                pendingIsScanned = true
                showScanner      = false
            }
            .ignoresSafeArea()
        }

        // MARK: - Photo Picker
        .sheet(
            isPresented: $showPhotoPicker,
            onDismiss: {
                guard !pendingImages.isEmpty else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    showSaveSheet = true
                }
            }
        ) {
            PhotoPickerView { image in
                pendingImages    = [image]
                pendingIsScanned = false
                // PhotoPickerView calls dismiss() itself after this
            }
        }

        // MARK: - Save Document + Category Picker
        .sheet(isPresented: $showSaveSheet, onDismiss: {
            pendingImages = []   // clear after save or cancel
        }) {
            SaveDocumentSheet(images: pendingImages, isScanned: pendingIsScanned)
        }
    }
}

#Preview {
    ContentView()
        .environment(AppViewModel())
}
