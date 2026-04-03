//
//  SaveDocumentSheet.swift
//  DocMate
//
//  Created by Shashwat kumar on 03/04/26.
//

import SwiftUI

struct SaveDocumentSheet: View {
    
    @Environment(AppViewModel.self) var viewModel
    @Environment(\.dismiss) var dismiss
    
    let images: [UIImage]
    let isScanned: Bool
    
    @State private var name: String = "Scanned Document"
    @State private var selectedCategoryId: UUID = AppViewModel.otherId
    
    var body: some View {
        
        NavigationStack {
            VStack(spacing: 16) {
                
                //  Preview
                if let img = images.first {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .cornerRadius(12)
                }
                
                //  Rename
                TextField("Document Name", text: $name)
                    .textFieldStyle(.roundedBorder)
                
                //  Category Picker
                Picker("Category", selection: $selectedCategoryId) {
                    ForEach(viewModel.categories) { cat in
                        Text(cat.name).tag(cat.id)
                    }
                }
                .pickerStyle(.menu)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Save Document")
            .toolbar {
                
                //  Cancel
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                // Save
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    func save() {
        let doc = Document(
            name: name,
            userId: viewModel.user.id,
            categoryId: selectedCategoryId
        )
        
        viewModel.addDocument(doc, images: images)
        dismiss()
    }
    
}



//#Preview {
//    SaveDocumentSheet()
//}
