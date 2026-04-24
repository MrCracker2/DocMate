//
//  ScannerFlowViewModel.swift
//  DocMateDummy
//

import SwiftUI
import Vision

//  Navigation Route (TOP LEVEL)
enum ScannerRoute: Hashable {
    case save(Date?)
}
@MainActor
@Observable
class ScannerFlowViewModel {

    // MARK: - Phase (ONLY for UI states, not navigation)
    enum Phase {
        case scanning
        case reviewing
        case detectingExpiry
        case expiryResult(Date)
        case noDateFound
    }

    // MARK: - State Stored Properties
    var phase: Phase = .scanning

    //  Navigation Path (NEW)
    var path: [ScannerRoute] = []

    var scannedImages: [UIImage] = []
    var extractedText: String = ""

    // MARK: - Parser
    private let parser = DateParser()

    // MARK: - Scan Complete
    func onScanComplete(_ images: [UIImage]) {
        scannedImages = images
        phase = .reviewing
    }

    // MARK: - Skip → navigate to Save (no date)
    func skip() {
        path.append(.save(nil))   //  PUSH instead of phase switch
    }

    // MARK: - Confirm date → navigate to Save
    func confirmDate(_ date: Date) {
        path.append(.save(date))  //  PUSH
    }

    // MARK: - Back Navigation
    func goBack() {
        if !path.isEmpty {
            path.removeLast()     //  POP
        } else {
            phase = .reviewing   // fallback (rare case)
        }
    }

    // MARK: - Detect Expiry Date
    func detectExpiryDate() {
        phase = .detectingExpiry

        Task {
            var combinedText = ""

            for image in self.scannedImages {
                if let cgImage = image.cgImage {
                    let text = await self.extractText(from: cgImage)
                    combinedText += text + "\n"
                }
            }

            //  Offload heavy parsing to background
            let result = await Task.detached(priority: .userInitiated) { [parser] in
                parser.parse(from: combinedText)
            }.value

            //  UI updates stay on main actor
            self.extractedText = combinedText

            if let expiry = result.expiryDate {
                self.phase = .expiryResult(expiry)
            } else {
                self.phase = .noDateFound
            }
        }
    }

    // MARK: - Vision OCR (SORTED + SAFE)
    nonisolated private func extractText(from cgImage: CGImage) async -> String {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNRecognizeTextRequest { req, _ in
                    guard let observations = req.results as? [VNRecognizedTextObservation] else {
                        continuation.resume(returning: "")
                        return
                    }
                    let sorted = observations.sorted {
                        if $0.boundingBox.minY != $1.boundingBox.minY {
                            return $0.boundingBox.minY > $1.boundingBox.minY
                        }
                        return $0.boundingBox.minX < $1.boundingBox.minX
                    }
                    let text = sorted
                        .compactMap { $0.topCandidates(1).first?.string }
                        .joined(separator: "\n")
                    continuation.resume(returning: text)
                }
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try? handler.perform([request])
            }
        }
    }
}
