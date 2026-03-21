//
//  DocumentMetaDataView.swift
//  DocMate
//
//  Created by Shashwat kumar on 20/03/26.
//

import SwiftUI

struct DocumentMetaDataView: View {

    @Environment(AppViewModel.self) var appViewModel
    @Bindable var vm: InFetchViewModel

    @State private var fullscreenAsset: String? = nil

    var allCategorized: Bool {
        vm.docMetaList.allSatisfy { $0.category != nil }
    }

    var body: some View {
        ZStack(alignment: .bottom) {

            ScrollView(showsIndicators:false){
                VStack(spacing: 16) {
                    ForEach($vm.docMetaList) { $meta in
                        DocMetaCard(
                            meta: $meta,
                            categories: appViewModel.categories,
                            onPreviewTap: {
                                fullscreenAsset = meta.assetName
                            }
                        )
                        .padding(.horizontal)
                    }
                    Spacer().frame(height: 90)
                }
                .padding(.top, 8)
            }
            .background(Color(.systemGray5).ignoresSafeArea())

            // Floating Save Button
            Button {
                vm.saveToMainModel(appViewModel: appViewModel)
                vm.reset()
                // Home tab pe switch karo
                appViewModel.selectedTab = 0
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Save \(vm.docMetaList.count) Document\(vm.docMetaList.count == 1 ? "" : "s")")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(allCategorized ? Color.blue : Color.gray.opacity(0.4))
                .foregroundColor(.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            }
            .disabled(!allCategorized)
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .navigationTitle("Add Details")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    vm.fetchState = .results
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").fontWeight(.semibold)
                        Text("Back")
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .fullScreenCover(item: Binding(
            get: { fullscreenAsset.map { NamedAsset(name: $0) } },
            set: { fullscreenAsset = $0?.name }
        )) { asset in
            LightboxView(assetName: asset.name)
        }
    }
}

// MARK: - Lightbox
private struct NamedAsset: Identifiable {
    var id: String { name }
    let name: String
}

private struct LightboxView: View {
    let assetName: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let uiImage = UIImage(named: assetName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .padding(16)
            }
            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.85))
                            .padding()
                    }
                }
                Spacer()
            }
        }
    }
}

// MARK: - Card
private struct DocMetaCard: View {

    @Binding var meta: InFetchViewModel.DocMeta
    var categories: [Category]
    var onPreviewTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {

            // IMAGE — only this has tap gesture
            ZStack(alignment: .bottomTrailing) {
                if let name = meta.assetName, let img = UIImage(named: name) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
                        .clipped()
                        .contentShape(Rectangle())
                        .onTapGesture { onPreviewTap() }
                } else {
                    ZStack {
                        Color(.systemGray4).frame(maxWidth: .infinity).frame(height: 160)
                        VStack(spacing: 8) {
                            Image(systemName: "doc.text").font(.largeTitle).foregroundColor(.secondary)
                            Text("No Preview").font(.caption).foregroundColor(.secondary)
                        }
                    }
                }

                if meta.assetName != nil {
                    Label("Tap to expand", systemImage: "arrow.up.left.and.arrow.down.right")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(.black.opacity(0.45))
                        .clipShape(Capsule())
                        .padding(8)
                        .allowsHitTesting(false)
                }
            }
            .clipShape(UnevenRoundedRectangle(
                topLeadingRadius: 16, bottomLeadingRadius: 0,
                bottomTrailingRadius: 0, topTrailingRadius: 16
            ))

            // DETAILS — no tap gestures
            VStack(spacing: 12) {

                HStack {
                    Image(systemName: "doc.fill").foregroundColor(.blue).frame(width: 20)
                    Text(meta.document.name)
                        .font(.subheadline).fontWeight(.semibold).lineLimit(1)
                    Spacer()
                }

                Divider()

                HStack {
                    Image(systemName: "folder.fill").foregroundColor(.orange).frame(width: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Category").font(.caption).foregroundColor(.gray)
                        Text(meta.category?.name ?? "Select Category")
                            .font(.subheadline).fontWeight(.medium)
                            .foregroundColor(meta.category == nil ? .gray : .primary)
                    }
                    Spacer()
                    Menu {
                        ForEach(categories) { cat in
                            Button {
                                meta.category = cat
                            } label: {
                                Label(cat.name, systemImage: cat.sfSymbol)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(meta.category == nil ? "Select" : "Change").font(.caption)
                            Image(systemName: "chevron.up.chevron.down").font(.caption)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }

                Divider()

                HStack {
                    Image(systemName: "calendar.badge.clock").foregroundColor(.red).frame(width: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Expiry Date").font(.caption).foregroundColor(.gray)
                        Text(meta.expiryDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline).fontWeight(.medium)
                    }
                    Spacer()
                    DatePicker("", selection: $meta.expiryDate, displayedComponents: .date)
                        .labelsHidden()
                }
            }
            .padding(16)
            .background(Color(.systemGray6))
            .clipShape(UnevenRoundedRectangle(
                topLeadingRadius: 0, bottomLeadingRadius: 16,
                bottomTrailingRadius: 16, topTrailingRadius: 0
            ))
        }
        .shadow(color: .black.opacity(0.07), radius: 6, x: 0, y: 3)
    }
}


