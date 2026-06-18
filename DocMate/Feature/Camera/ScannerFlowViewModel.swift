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

    /// True when OCR could not read any usable text from the scan (e.g. blurry
    /// or blank page) — used to show a "retake a clearer photo" hint instead of
    /// a generic "no date" message.
    var ocrFoundNoText: Bool = false

    // MARK: - Parser
    private let parser = DateParser()

    /// The in-flight OCR run, so it can be cancelled if the user navigates away.
    private var detectionTask: Task<Void, Never>?

    /// Minimum Vision confidence (0...1) for a recognized line to be trusted.
    nonisolated static let minTextConfidence: Float = 0.3

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
        // If we pushed a route (e.g. Save screen), pop it first.
        if !path.isEmpty {
            path.removeLast()     //  POP
            return
        }

        // Otherwise step back through the review phases.
        switch phase {
        case .detectingExpiry, .expiryResult, .noDateFound:
            // Back from an OCR sub-state → return to the review start.
            detectionTask?.cancel()
            phase = .reviewing
        case .reviewing, .scanning:
            // Back from the review start → return to the camera.
            phase = .scanning
        }
    }

    // MARK: - Detect Expiry Date
    func detectExpiryDate() {
        // Cancel any previous run so a stale result can't overwrite the UI.
        detectionTask?.cancel()
        phase = .detectingExpiry

        let images = scannedImages

        detectionTask = Task {
            // OCR every page concurrently, then reassemble in page order.
            let pages = await withTaskGroup(of: (Int, String).self) { group -> [String] in
                for (index, image) in images.enumerated() {
                    group.addTask { (index, await self.extractText(from: image)) }
                }
                var byIndex: [Int: String] = [:]
                for await (index, text) in group {
                    byIndex[index] = text
                }
                return images.indices.map { byIndex[$0] ?? "" }
            }

            if Task.isCancelled { return }

            let combinedText = pages.joined(separator: "\n")

            //  Offload heavy parsing to background. Parse per-page to avoid a
            //  keyword on one page matching a date on the next.
            let result = await Task.detached(priority: .userInitiated) { [parser] in
                parser.parse(pages: pages)
            }.value

            // The user may have navigated away (Back) while OCR was running.
            // Only apply the result if we're still on the detecting screen.
            if Task.isCancelled { return }
            guard case .detectingExpiry = self.phase else { return }

            //  UI updates stay on main actor
            self.extractedText = combinedText
            self.ocrFoundNoText = combinedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

            if let expiry = result.expiryDate {
                self.phase = .expiryResult(expiry)
            } else {
                self.phase = .noDateFound
            }
        }
    }

    // MARK: - Vision OCR (SORTED + SAFE)
    nonisolated private func extractText(from image: UIImage) async -> String {
        guard let cgImage = image.cgImage else { return "" }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNRecognizeTextRequest { req, _ in
                    guard let observations = req.results as? [VNRecognizedTextObservation] else {
                        continuation.resume(returning: "")
                        return
                    }
                    let sorted = observations.sorted {
                        // Bucket minY with a small tolerance so fragments on the same
                        // visual row are grouped and ordered left-to-right.
                        let tolerance = 0.01
                        if abs($0.boundingBox.minY - $1.boundingBox.minY) > tolerance {
                            return $0.boundingBox.minY > $1.boundingBox.minY
                        }
                        return $0.boundingBox.minX < $1.boundingBox.minX
                    }
                    let text = sorted
                        .compactMap { observation -> String? in
                            // Drop low-confidence reads so OCR noise never reaches
                            // the date parser.
                            guard let candidate = observation.topCandidates(1).first,
                                  candidate.confidence >= Self.minTextConfidence else { return nil }
                            return candidate.string
                        }
                        .joined(separator: "\n")
                    continuation.resume(returning: text)
                }
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                request.recognitionLanguages = ["en-US"]
                let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
                do {
                    try handler.perform([request])
                } catch {
                    // If Vision fails to run the request its completion handler is never
                    // called, so resume here to avoid hanging the continuation forever.
                    continuation.resume(returning: "")
                }
            }
        }
    }
}

// MARK: - UIImage.Orientation → CGImagePropertyOrientation
extension CGImagePropertyOrientation {
    nonisolated init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up:            self = .up
        case .upMirrored:    self = .upMirrored
        case .down:          self = .down
        case .downMirrored:  self = .downMirrored
        case .left:          self = .left
        case .leftMirrored:  self = .leftMirrored
        case .right:         self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default:    self = .up
        }
    }
}
