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
        pdfView.document = PDFDocument(url: url)

        // Native-style (Apple Preview) reading experience.
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.autoScales = true
        pdfView.pageShadowsEnabled = true
        pdfView.pageBreakMargins = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        pdfView.backgroundColor = .secondarySystemBackground // gray canvas like Preview

        // Fit the page to the width and pin it to the top (no vertical centering).
        DispatchQueue.main.async {
            let fit = pdfView.scaleFactorForSizeToFit
            pdfView.minScaleFactor = fit
            pdfView.maxScaleFactor = 5
            pdfView.scaleFactor = fit
            (pdfView.documentView as? UIScrollView)?.contentInset = .zero
        }
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document?.documentURL != url {
            uiView.document = PDFDocument(url: url)
            DispatchQueue.main.async {
                let fit = uiView.scaleFactorForSizeToFit
                uiView.minScaleFactor = fit
                uiView.scaleFactor = fit
            }
        }
    }
}

