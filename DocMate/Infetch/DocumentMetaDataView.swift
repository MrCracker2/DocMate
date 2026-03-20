//
//  DocumentMetaDataView.swift
//  DocMate
//
//  Created by Shashwat kumar on 20/03/26.
//

import SwiftUI

struct DocumentMetaDataView: View {
    
    @Environment(AppViewModel.self) var viewModel
    
    var selectedDocs: [Document]
    
    // MARK: - Per Document State
    struct DocMeta {
        var document: Document
        var category: Category?
        var expiryDate: Date = Date()
    }
    
    @State private var docMetaList: [DocMeta] = []
    
    // MARK: - Init
    init(selectedDocs: [Document]) {
        self.selectedDocs = selectedDocs
        _docMetaList = State(initialValue: selectedDocs.map {
            DocMeta(document: $0)
        })
    }
    
    var body: some View {
        
        VStack(spacing: 20) {
            
            // MARK: Header
            Text("Add Details")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top)
            
            // MARK: List
            ScrollView {
                VStack(spacing: 16) {
                    
                    ForEach(docMetaList.indices, id: \.self) { index in
                        
                        let doc = docMetaList[index].document
                        
                        VStack(spacing: 12) {
                            
                            // MARK: Document Name
                            HStack {
                                Text(doc.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Spacer()
                            }
                            
                            // MARK: Category Picker
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Category")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    Text(docMetaList[index].category?.name ?? "Select Category")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                
                                Spacer()
                                
                                Menu {
                                    ForEach(viewModel.categories) { cat in
                                        Button(cat.name) {
                                            docMetaList[index].category = cat
                                        }
                                    }
                                } label: {
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(14)
                            
                            // MARK: Date Picker
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Expiry Date")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    Text(
                                        docMetaList[index].expiryDate.formatted(date: .abbreviated, time: .omitted)
                                    )
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                }
                                
                                Spacer()
                                
                                DatePicker(
                                    "",
                                    selection: $docMetaList[index].expiryDate,
                                    displayedComponents: .date
                                )
                                .labelsHidden()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(14)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // MARK: Save Button
                Button(action: {
                    saveDocuments()
                }) {
                    Text("Save Documents")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
                .padding()
            }
            .background(Color(.systemGray5))
        }
        
        
    }
    
    
    
    
    
    // MARK: - Save Logic
    private func saveDocuments() {
        for item in docMetaList {
            
            guard let category = item.category else { continue }
            
            let newDoc = Document(
                name: item.document.name,
                dueDate: item.expiryDate,
                isPinned: false,
                userId: viewModel.user.id,
                categoryId: category.id,
                createdAt: Date(),
                fileType: item.document.fileType
            )
            
            viewModel.documents.append(newDoc)
        }
    }
}
