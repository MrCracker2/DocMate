//
//  ExportDocumentView.swift
//  DocMate
//
//  Apple Preview-style export sheet: choose format + options and share.
//

import SwiftUI
import ImageIO
import PDFKit

// MARK: - Export Format

enum ExportFormat: String, CaseIterable, Identifiable {
    case heic = "HEIC"
    case jpeg = "JPEG"
    case png  = "PNG"
    case tiff = "TIFF"
    case pdf  = "PDF"

    nonisolated var id: String { rawValue }
    nonisolated var label: String { rawValue }
    nonisolated var fileExtension: String {
        switch self {
        case .heic: return "heic"
        case .jpeg: return "jpg"
        case .png:  return "png"
        case .tiff: return "tiff"
        case .pdf:  return "pdf"
        }
    }
    /// Lossy formats expose a quality slider.
    nonisolated var isLossy: Bool { self == .heic || self == .jpeg }
    /// Formats that support an alpha channel.
    nonisolated var supportsAlpha: Bool { self == .png || self == .tiff }
}

// MARK: - Export View

struct ExportDocumentView: View {

    @Environment(\.dismiss) private var dismiss

    let image: UIImage
    let fileName: String

    @State private var format: ExportFormat = .jpeg
    @State private var quality: Double = 0.8
    @State private var ppi: Double = 72
    @State private var customResolution = false
    @State private var customPPI: Double = 150
    @State private var includeAlpha = true
    @State private var estimatedBytes = 0
    @State private var isExporting = false
    @State private var estimateTask: Task<Void, Never>?

    @State private var shareItem: ShareItem?

    private let resolutions: [Double] = [72, 150, 300]

    /// The resolution actually used for export (preset or custom).
    private var effectivePPI: Double { customResolution ? customPPI : ppi }

    var body: some View {
        NavigationStack {
            Form {
                Section("Format") {
                    Picker("Format", selection: $format) {
                        ForEach(ExportFormat.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text("Estimated Size")
                        Spacer()
                        Text(sizeText).foregroundStyle(.secondary)
                    }
                }

                Section("Options") {
                    if format.isLossy {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Quality")
                            HStack {
                                Text("Least").font(.caption).foregroundStyle(.secondary)
                                Slider(value: $quality, in: 0...1) { editing in
                                    if !editing { recomputeSize() }
                                }
                                Text("Best").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }

                    if format != .pdf {
                        Toggle("Custom Resolution", isOn: $customResolution)

                        if customResolution {
                            Stepper(value: $customPPI, in: 50...600, step: 10) {
                                Text("\(Int(customPPI)) pixels/inch")
                            }
                        } else {
                            Picker("Resolution", selection: $ppi) {
                                ForEach(resolutions, id: \.self) { Text("\(Int($0)) pixels/inch").tag($0) }
                            }
                        }
                    }

                    if format.supportsAlpha {
                        Toggle("Alpha", isOn: $includeAlpha)
                    }

                    if format == .pdf {
                        Text("No options for this format.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isExporting {
                        ProgressView()
                    } else {
                        Button("Export") { export() }
                    }
                }
            }
            .onAppear(perform: recomputeSize)
            .onChange(of: format) { _, _ in recomputeSize() }
            .onChange(of: ppi) { _, _ in recomputeSize() }
            .onChange(of: customResolution) { _, _ in recomputeSize() }
            .onChange(of: customPPI) { _, _ in recomputeSize() }
            .onChange(of: includeAlpha) { _, _ in recomputeSize() }
            .sheet(item: $shareItem) { item in
                ShareSheet(items: [item.url])
            }
        }
    }

    private var sizeText: String {
        guard estimatedBytes > 0 else { return "—" }
        let f = ByteCountFormatter()
        f.allowedUnits = [.useKB, .useMB]
        f.countStyle = .file
        return f.string(fromByteCount: Int64(estimatedBytes))
    }

    // MARK: Encoding (runs off the main thread to keep the UI smooth)

    private func recomputeSize() {
        estimateTask?.cancel()
        let img = image, fmt = format, q = quality, p = effectivePPI, a = includeAlpha
        estimateTask = Task.detached(priority: .utility) {
            let bytes = Self.encode(image: img, format: fmt, quality: q, ppi: p, includeAlpha: a)?.count ?? 0
            if Task.isCancelled { return }
            await MainActor.run { estimatedBytes = bytes }
        }
    }

    private func export() {
        isExporting = true
        let img = image, fmt = format, q = quality, p = effectivePPI, a = includeAlpha
        let safeName = fileName.isEmpty ? "Document" : fileName
        let ext = fmt.fileExtension
        Task.detached(priority: .userInitiated) {
            let data = Self.encode(image: img, format: fmt, quality: q, ppi: p, includeAlpha: a)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(safeName).\(ext)")
            let written: URL?
            if let data {
                do { try data.write(to: url); written = url }
                catch { print("Export write failed: \(error)"); written = nil }
            } else {
                written = nil
            }
            await MainActor.run {
                isExporting = false
                if let written { shareItem = ShareItem(url: written) }
            }
        }
    }

    nonisolated private static func encode(image: UIImage, format: ExportFormat,
                                           quality: Double, ppi: Double, includeAlpha: Bool) -> Data? {
        if format == .pdf { return PDFConverter.makePDF(from: [image]) }

        let source = resampled(image, ppi: ppi)
        switch format {
        case .jpeg:
            return source.jpegData(compressionQuality: quality)
        case .png:
            return (includeAlpha ? source : flattened(source)).pngData()
        case .tiff:
            return encodedImage(includeAlpha ? source : flattened(source), uti: "public.tiff", quality: nil)
        case .heic:
            return encodedImage(source, uti: "public.heic", quality: quality)
        case .pdf:
            return nil
        }
    }

    /// Resamples the image so its pixel size scales with the chosen resolution.
    nonisolated private static func resampled(_ image: UIImage, ppi: Double) -> UIImage {
        let factor = max(0.1, ppi / 72)
        var size = CGSize(width: image.size.width * factor, height: image.size.height * factor)
        let maxDim: CGFloat = 4000
        let longest = max(size.width, size.height)
        if longest > maxDim {
            let s = maxDim / longest
            size = CGSize(width: size.width * s, height: size.height * s)
        }
        let fmt = UIGraphicsImageRendererFormat.default()
        fmt.scale = 1
        return UIGraphicsImageRenderer(size: size, format: fmt).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    /// Flattens transparency onto white (used when Alpha is off).
    nonisolated private static func flattened(_ image: UIImage) -> UIImage {
        let fmt = UIGraphicsImageRendererFormat.default()
        fmt.scale = 1
        fmt.opaque = true
        return UIGraphicsImageRenderer(size: image.size, format: fmt).image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: image.size))
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    /// Encodes via ImageIO for formats UIImage can't produce directly (HEIC, TIFF).
    nonisolated private static func encodedImage(_ image: UIImage, uti: String, quality: Double?) -> Data? {
        guard let cg = image.cgImage else { return nil }
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(
            data, uti as CFString, 1, nil) else { return nil }
        var options: [CFString: Any] = [:]
        if let quality { options[kCGImageDestinationLossyCompressionQuality] = quality }
        CGImageDestinationAddImage(dest, cg, options as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return data as Data
    }
}

// MARK: - Helpers

/// Identifiable wrapper so the share sheet can be presented via `.sheet(item:)`.
struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

extension UIImage {
    /// Returns the image rotated 90° in the given direction.
    func rotated(clockwise: Bool) -> UIImage? {
        let radians: CGFloat = clockwise ? .pi / 2 : -.pi / 2
        let newSize = CGSize(width: size.height, height: size.width)
        let fmt = UIGraphicsImageRendererFormat.default()
        fmt.scale = scale
        return UIGraphicsImageRenderer(size: newSize, format: fmt).image { ctx in
            let c = ctx.cgContext
            c.translateBy(x: newSize.width / 2, y: newSize.height / 2)
            c.rotate(by: radians)
            draw(in: CGRect(x: -size.width / 2, y: -size.height / 2,
                            width: size.width, height: size.height))
        }
    }
}
