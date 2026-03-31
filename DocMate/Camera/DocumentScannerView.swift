//
//  DocumentScannerView.swift
//  DocMateDummy
//
//  Created by Shashwat kumar on 30/03/26.
//

import SwiftUI
import VisionKit

struct DocumentScannerView: UIViewControllerRepresentable {
    
    var onScanComplete: ([UIImage]) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        
        let parent: DocumentScannerView
        
        init(_ parent: DocumentScannerView) {
            self.parent = parent
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFinishWith scan: VNDocumentCameraScan) {
            
            var images: [UIImage] = []
            
            for i in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: i))
            }
            
            parent.onScanComplete(images)
            controller.dismiss(animated: true)
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFailWithError error: Error) {
            print("Scan error:", error)
            controller.dismiss(animated: true)
        }
    }
}
