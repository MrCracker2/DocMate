//
//  DocumentScannerView.swift
//  DocMate
//
//  Created by Shashwat kumar on 30/03/26.
//
//1
import SwiftUI
import VisionKit

struct DocumentScannerView: UIViewControllerRepresentable {
    
    var onScanComplete: ([UIImage]) -> Void         // send scanned image back to app
    
    func makeCoordinator() -> Coordinator {         // use delegates
        Coordinator(self)
    }

    // MARK Uses VIsionKit
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
                // Convert scaned page -> array of image
            for i in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: i))
            }
            
            parent.onScanComplete(images)       // send image back to ui
            controller.dismiss(animated: true)      // close the scanner
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }
            // closes the function with error printed
        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFailWithError error: Error) {
            print("Scan error:", error)
            controller.dismiss(animated: true)
        }
    }
}
