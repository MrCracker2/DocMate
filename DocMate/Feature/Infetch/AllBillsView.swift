//
//  AllBillsView.swift
//  DocMate
//
//  Created by Naman Yadav on 25/03/26.
//
//  AllBillsView.swift
//  DocMate
//

import SwiftUI

struct AllBillsView: View {
    
    @Environment(AppViewModel.self) var viewModel
    @State private var selectedCategory: InfetchCategory? = nil
    @State private var selectedBill: Infetch? = nil
    @State private var showPaidToast = false
    @State private var toastBillName = ""

    var body: some View {
        
        ScrollView {
            VStack(spacing: 16) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        
                        CategoryChip(
                            title: "All",
                            isSelected: selectedCategory == nil
                        ) {
                            selectedCategory = nil
                        }
                        
                        ForEach(InfetchCategory.allCases) { cat in
                            CategoryChip(
                                title: cat.rawValue,
                                isSelected: selectedCategory == cat
                            ) {
                                selectedCategory = cat
                            }
                        }
                    }
                }
                
                ForEach(filteredBills) { doc in
                    AllBillsCard(doc: doc) {
                        markAsPaid(doc)
                    }
                    .onTapGesture {
                        selectedBill = doc
                    }
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .opacity.combined(with: .move(edge: .trailing))
                    ))
                }
            }
            .padding()
        }
        .navigationTitle("All Bills")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedBill) { bill in
            BillSheetView(doc: bill)
                .presentationDetents([.medium, .large])
        }
        .overlay(alignment: .bottom) {
            if showPaidToast {
                PaidToastView(billName: toastBillName)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 16)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showPaidToast)
    }
    
    // MARK: - Mark as paid
    private func markAsPaid(_ bill: Infetch) {
        Task {
            await viewModel.markBillAsPaid(bill)
        }

        toastBillName = bill.name
        showPaidToast = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation { showPaidToast = false }
        }
    }

    // MARK: - Filtered bills
    var filteredBills: [Infetch] {
        if let selectedCategory {
            return viewModel.inFetch.filter {
                $0.inFetchCatgogry == selectedCategory
            }
        } else {
            return viewModel.inFetch
        }
    }
}

// MARK: - CategoryChip
struct CategoryChip: View {
    
    var title: String
    var isSelected: Bool
    var onTap: () -> Void
    
    var body: some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
            .onTapGesture { onTap() }
    }
}

// MARK: - PaidToastView
struct PaidToastView: View {

    let billName: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 1) {
                Text("Bill Paid!")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("\(billName) added to Bills History")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 16)
    }
}
