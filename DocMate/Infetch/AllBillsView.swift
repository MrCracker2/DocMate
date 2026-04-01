//
//  AllBillsView.swift
//  DocMate
//
//  Created by Naman Yadav on 25/03/26.
//


import SwiftUI

struct AllBillsView: View {
    
    @Environment(AppViewModel.self) var viewModel
    @State private var selectedCategory: InfetchCategory? = nil
    
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
                        refreshBill(doc)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("All Bills")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Refresh Logic
    func refreshBill(_ doc: infetch) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            
            let isPaid = Bool.random() // API replace later
            
            if isPaid {
                withAnimation {
                    viewModel.inFetch.removeAll { $0.id == doc.id }
                }
            }
        }
    }
    // Fillterd documents
    var filteredBills: [infetch] {
        
        if let selectedCategory {
            return viewModel.inFetch.filter {
                $0.inFetchCatgogry == selectedCategory
            }
        } else {
            return viewModel.inFetch
        }
    }
}

// MARK:- category list ko scrollable banane ke liye

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
            .background(
                isSelected ? Color.blue : Color.gray.opacity(0.2)
            )
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
            .onTapGesture {
                onTap()
            }
    }
}
