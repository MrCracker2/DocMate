//
//  PDFConverter.swift
//  DocMate
//
//  Created by Shashwat kumar on 25/04/26.
//

import UIKit

struct PDFConverter {

    /// Converts an array of UIImages into PDF Data.
    ///
    /// Pages are downscaled to `maxDimension` and JPEG re-encoded before being
    /// drawn, so a full-resolution camera scan (often several MB/page) produces
    /// a much smaller PDF — dramatically faster to upload without a visible
    /// quality loss for documents.
    nonisolated static func makePDF(
        from images: [UIImage],
        maxDimension: CGFloat = 2000,
        jpegQuality: CGFloat = 0.6
    ) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: .zero)

        return renderer.pdfData { context in
            for image in images {
                let prepared = compressedPage(from: image,
                                              maxDimension: maxDimension,
                                              jpegQuality: jpegQuality)
                let pageRect = CGRect(origin: .zero, size: prepared.size)
                context.beginPage(withBounds: pageRect, pageInfo: [:])
                prepared.draw(in: pageRect)
            }
        }
    }

    /// Downscales an image so its longest side is at most `maxDimension`, then
    /// JPEG re-encodes it to shed pixel data. Returns the original if anything
    /// fails so we never lose a page.
    private nonisolated static func compressedPage(
        from image: UIImage,
        maxDimension: CGFloat,
        jpegQuality: CGFloat
    ) -> UIImage {
        let scaled = downscaled(image, maxDimension: maxDimension)
        guard let jpeg = scaled.jpegData(compressionQuality: jpegQuality),
              let reloaded = UIImage(data: jpeg) else {
            return scaled
        }
        return reloaded
    }

    /// Produces a tiny JPEG preview (≈ `maxDimension` px on its long side) for
    /// upload, so browsing never has to download a full PDF.
    nonisolated static func thumbnailJPEG(
        from image: UIImage,
        maxDimension: CGFloat = 400,
        quality: CGFloat = 0.6
    ) -> Data? {
        downscaled(image, maxDimension: maxDimension).jpegData(compressionQuality: quality)
    }

    private nonisolated static func downscaled(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxDimension, longest > 0 else { return image }

        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
