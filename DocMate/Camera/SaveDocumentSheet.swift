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
            
            ZStack(alignment: .bottom) {
                
                // ✅ BrowseView with selection mode
                BrowseView(
                    isSelecting: true,
                    selectedCategoryId: $selectedCategoryId
                )
                .padding(.bottom, 90) // space for floating bar
                
                // ✅ Only ONE bottom bar
                bottomSaveBar
            }
            .navigationTitle("Browse")
            .animation(.easeInOut, value: selectedCategoryId)
            
            .toolbar {
                
                //  Cancel
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
                
                // Save
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedCategoryId == AppViewModel.otherId)
                }
            }
        }
    }
    
    // MARK: - Bottom Floating Bar
    var bottomSaveBar: some View {
        
        HStack {
            
            if let img = images.first {
                Image(uiImage: img)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .cornerRadius(6)
            }
            
            VStack(alignment: .leading) {
                Text("Save as")
                    .font(.caption)
                    .foregroundStyle(.gray)
                
                Text(name)
                    .fontWeight(.medium)
                
                Text(
                    viewModel.categories
                        .first(where: { $0.id == selectedCategoryId })?.name ?? "Select folder"
                )
                .font(.caption2)
                .foregroundStyle(.blue)
            }
            
            Spacer()
            
            Button {
                // future rename
            } label: {
                Image(systemName: "pencil.circle")
                    .font(.title3)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(radius: 10)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    // MARK: - Save
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
