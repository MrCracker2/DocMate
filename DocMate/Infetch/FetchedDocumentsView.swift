//
//  DocumentMetaDataView.swift
//  DocMate
//
//  Created by Naman Yadav on 20/03/26.
//

import SwiftUI

struct FetchedDocumentsView: View {
    
    var documents: [Document]
    @Binding var selectedDocs: Set<UUID>
    
    @State private var goToMeta: Bool = false
    
    var body: some View {
        
        VStack(spacing: 16) {
            
            // MARK: Header
            HStack(spacing: 12) {
                Image(systemName: "chevron.left")
                    .font(.headline)
                
                Text("InFetch")
                    .font(.headline)
                
                Spacer()
            }
            .padding(.horizontal)
            
            // MARK: Documents Count
            HStack {
                Text("\(documents.count) Documents Found")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .padding(.horizontal)
            
            // MARK: List
            ScrollView {
                VStack(spacing: 12) {
                    
                    ForEach(documents) { doc in
                        
                        DocumentRowView(
                            doc: doc,
                            isSelected: selectedDocs.contains(doc.id)
                        )
                        .onTapGesture {
                            toggleSelection(doc)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            
            Spacer()
            
            // MARK: Continue Button
            Button(action: {
                goToMeta = true
            }) {
                Text("Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        selectedDocs.isEmpty
                        ? Color.gray.opacity(0.5)
                        : Color.blue
                    )
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }
            .disabled(selectedDocs.isEmpty)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color(.systemGray5))
        .navigationDestination(isPresented: $goToMeta) {
            DocumentMetaDataView(
                selectedDocs: documents.filter { selectedDocs.contains($0.id) }
            )
        }
    }
    
    // MARK: - Selection Logic
    private func toggleSelection(_ doc: Document) {
        if selectedDocs.contains(doc.id) {
            selectedDocs.remove(doc.id)
        } else {
            selectedDocs.insert(doc.id)
        }
    }
}

