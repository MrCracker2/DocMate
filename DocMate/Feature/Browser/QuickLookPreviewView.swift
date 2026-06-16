//
//  QuickLookPreviewView.swift
//  DocMate
//
//  Created by Shashwat Kumar on 16/06/26.
//

import SwiftUI
import QuickLook

struct QuickLookPreviewView: UIViewControllerRepresentable {
    let url: URL
    let onSave: (URL) -> Void
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
        var parent: QuickLookPreviewView

        init(parent: QuickLookPreviewView) {
            self.parent = parent
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return parent.url as NSURL
        }

        // Enable editing
        func previewController(_ controller: QLPreviewController, editingModeFor previewItem: QLPreviewItem) -> QLPreviewItemEditingMode {
            return .updateContents
        }

        func previewController(_ controller: QLPreviewController, didUpdateContentsOf previewItem: QLPreviewItem) {
            if let fileURL = previewItem.previewItemURL {
                parent.onSave(fileURL)
            }
        }

        func previewControllerDidDismiss(_ controller: QLPreviewController) {
            parent.onDismiss()
        }
    }
}
