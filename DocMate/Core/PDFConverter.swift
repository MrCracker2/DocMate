//
//  PDFConverter.swift
//  DocMate
//
//  Created by Shashwat kumar on 25/04/26.
//

import UIKit

struct PDFConverter {
    
    /// Converts an array of UIImages into PDF Data
    static func makePDF(from images: [UIImage]) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: .zero)
        
        return renderer.pdfData { context in
            for image in images {
                let pageRect = CGRect(
                    x: 0, y: 0,
                    width: image.size.width,
                    height: image.size.height
                )
                context.beginPage(withBounds: pageRect, pageInfo: [:])
                image.draw(in: pageRect)
            }
        }
    }
}

