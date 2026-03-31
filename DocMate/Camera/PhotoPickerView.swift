//
//  PhotoPickerView.swift
//  DocMateDummy
//
//  Created by Shashwat kumar on 30/03/26.
//

import SwiftUI
import PhotosUI

struct PhotoPickerView: View {
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?
    
    var onImagePicked: (UIImage) -> Void
    
    var body: some View {
        VStack {
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Text("Select Image")
                    .font(.headline)
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    
                    onImagePicked(image)
                    dismiss()
                }
            }
        }
    }
}
