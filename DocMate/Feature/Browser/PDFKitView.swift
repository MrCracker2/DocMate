//
//  PDFKitView.swift
//  DocMate
//
//  Created by Shashwat kumar on 25/04/26.
//

import SwiftUI
import PDFKit

struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()

        // Native-style (Apple Preview) reading experience.
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.autoScales = true
        pdfView.pageShadowsEnabled = true
        pdfView.pageBreakMargins = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        pdfView.backgroundColor = .secondarySystemBackground // gray canvas like Preview

        pdfView.document = PDFDocument(url: url)

        // Fit page-to-width once the view has its real bounds. The view is
        // rebuilt after every edit (via .id(previewVersion) at the call site),
        // so this fit runs again for edited pages too.
        fitToWidth(pdfView)
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document?.documentURL != url {
            uiView.document = PDFDocument(url: url)
            fitToWidth(uiView)
        }
    }

    private func fitToWidth(_ pdfView: PDFView) {
        DispatchQueue.main.async {
            let fit = pdfView.scaleFactorForSizeToFit
            guard fit > 0 else { return }
            pdfView.minScaleFactor = fit
            pdfView.maxScaleFactor = 5
            pdfView.scaleFactor = fit
            (pdfView.documentView as? UIScrollView)?.contentInset = .zero
        }
    }
}

