//
//  ScannerFlowView.swift
//  DocMate
//
//  Created by Shashwat kumar on 04/04/26.
//
//
//  ScannerFlowView.swift
//  DocMateDummy
//

import SwiftUI

struct ScannerFlowView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ScannerFlowViewModel()

    var body: some View {
        switch viewModel.phase {

        // MARK: - Camera
        case .scanning:
            DocumentScannerView(
                onScanComplete: { images in
                    viewModel.onScanComplete(images)
                },
                onCancel: {
                    dismiss()
                }
            )
            .ignoresSafeArea()

        // MARK: - Review + OCR states (all handled inside ReviewDocumentView)
        case .reviewing, .detectingExpiry, .expiryResult, .noDateFound:
            ReviewDocumentView(viewModel: viewModel)

        // MARK: - Save Sheet
        case .saving(let date):
            SaveDocumentSheet(
                images: viewModel.scannedImages,
                isScanned: true,
                detectedDate: date,
                onSaveComplete: {
                    dismiss()
                }
            )
        }
    }
}
