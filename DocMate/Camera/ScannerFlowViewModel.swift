//
//  ScannerFlowViewModel.swift
//  DocMateDummy
//

import SwiftUI
import Vision

@Observable
class ScannerFlowViewModel {

    // MARK: - Phase
    enum Phase {
        case scanning
        case reviewing
        case detectingExpiry
        case expiryResult(Date)
        case noDateFound
        case saving(Date?)
    }

    // MARK: - State
    var phase: Phase = .scanning
    var scannedImages: [UIImage] = []
    var extractedText: String = ""

    // MARK: - Parser
    private let parser = DateParser()

    // MARK: - Scan Complete
    func onScanComplete(_ images: [UIImage]) {
        scannedImages = images
        phase = .reviewing
    }

    // MARK: - Skip → go to save with no date
    func skip() {
        phase = .saving(nil)
    }

    // MARK: - Detect Expiry Date
    func detectExpiryDate() {
        phase = .detectingExpiry

        Task {

            var combinedText = ""

            // ✅ Multi-page OCR
            for image in self.scannedImages {
                if let cgImage = image.cgImage {
                    let text = await self.extractText(from: cgImage)
                    combinedText += text + "\n"
                }
            }

            // ✅ Parse dates using advanced parser
            let result = self.parser.parse(from: combinedText)

            // ✅ Update UI safely
            self.extractedText = combinedText

            if let expiry = result.expiryDate {
                self.phase = .expiryResult(expiry)
            } else {
                self.phase = .noDateFound
            }
        }
    }

    // MARK: - Confirm date → go to save
    func confirmDate(_ date: Date) {
        phase = .saving(date)
    }

    // MARK: - Vision OCR (FIXED + SORTED)
    nonisolated private func extractText(from cgImage: CGImage) async -> String {
        return await withCheckedContinuation { continuation in

            let request = VNRecognizeTextRequest { request, _ in

                // ✅ Get observations safely
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }

                // ✅ Sort text in correct reading order (CRITICAL)
                let sorted = observations.sorted {
                    if $0.boundingBox.minY != $1.boundingBox.minY {
                        return $0.boundingBox.minY > $1.boundingBox.minY   // top → bottom
                    }
                    return $0.boundingBox.minX < $1.boundingBox.minX       // left → right
                }

                // ✅ Extract text
                let text = sorted
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")

                // ✅ Return result
                continuation.resume(returning: text)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
}
