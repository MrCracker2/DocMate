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
        .onChange(of: selectedItem) { _, newItem in //Runs when user selects an image
            guard let newItem else { return }       // If nothing selected → stop
            
            Task {                                                                  // Runs async code (important because loading image takes time)
                if let data = try? await newItem.loadTransferable(type: Data.self),  // Fetches image data from photo library
                   let image = UIImage(data: data) {        // convert raw data -> usable image
                    
                    onImagePicked(image)    // claing the fun
                    dismiss()
                }
            }
        }
    }
}
