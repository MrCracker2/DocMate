//
//  FetchedDocumentsView.swift
//  DocMate
//
//  Created by Naman Yadav on 20/03/26.
//

import SwiftUI

struct FetchedDocumentsView: View {

    @Environment(AppViewModel.self) var appViewModel
    @Bindable var vm: InFetchViewModel

    var body: some View {
        ZStack(alignment: .bottom) {

            // MARK: Full screen scroll
            ScrollView (showsIndicators:false){
                VStack(spacing: 12) {
                    ForEach(vm.mappedDocs) { doc in
                        let fetched = vm.fetchedDocs.first { $0.name == doc.name }

                        DocumentRowView(
                            doc: doc,
                            assetName: fetched?.assetName,
                            previewText: fetched?.previewText,
                            isSelected: vm.isSelected(doc.id)
                        )
                        .onTapGesture {
                            vm.toggleSelection(doc.id)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 90) // floating button ke liye space
            }

            // MARK: Floating Continue Button
            Button {
                vm.proceedToMeta(userId: appViewModel.user.id)
            } label: {
                HStack {
                    Text("Continue")
                        .fontWeight(.semibold)
                    if !vm.selectedIds.isEmpty {
                        Text("(\(vm.selectedIds.count))")
                            .fontWeight(.regular)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(vm.selectedIds.isEmpty ? Color.gray.opacity(0.5) : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            }
            .disabled(vm.selectedIds.isEmpty)
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGray5).ignoresSafeArea())
        .navigationTitle("InFetch")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if vm.selectedIds.count == vm.mappedDocs.count {
                        vm.selectedIds.removeAll()
                    } else {
                        vm.selectedIds = Set(vm.mappedDocs.map { $0.id })
                    }
                } label: {
                    Text(vm.selectedIds.count == vm.mappedDocs.count ? "Deselect All" : "Select All")
                        .font(.subheadline)
                }
            }
        }
        .safeAreaInset(edge: .top) {
            // Documents count — navigation bar ke neeche
            HStack {
                Text("\(vm.mappedDocs.count) Documents Found")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGray5))
        }
    }
}
