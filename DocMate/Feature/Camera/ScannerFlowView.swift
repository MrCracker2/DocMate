//
//  ScannerFlowView.swift
//  DocMateDummy
//

import SwiftUI

struct ScannerFlowView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ScannerFlowViewModel()

    var body: some View {

        //  SINGLE ROOT NavigationStack
        NavigationStack(path: $viewModel.path) {

            // MARK: - Root Content
            contentView

                //  Navigation Destination (PUSH)
                .navigationDestination(for: ScannerRoute.self) { route in
                    switch route {

                    case .save(let date):
                        SaveDocumentSheet(
                            viewModel: viewModel,   //  IMPORTANT
                            images: viewModel.scannedImages,
                            isScanned: true,
                            detectedDate: date,
                            onSaveComplete: {
                                dismiss()   // close full flow AFTER save
                            }
                        )
                    }
                }
        }
    }

    // MARK: - Root View (ONLY 2 STATES NOW)
    @ViewBuilder
    private var contentView: some View {
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

        // MARK: - Review Flow (handles OCR states internally)
        default:
            ReviewDocumentView(viewModel: viewModel)
        }
    }
}
