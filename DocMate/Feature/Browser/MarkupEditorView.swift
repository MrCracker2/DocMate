//
//  MarkupEditorView.swift
//  DocMate
//
//  Native PencilKit-based markup / signature / crop editor.
//

import SwiftUI
import PencilKit
import PDFKit

/// Which editing tool the editor should open into.
enum MarkupMode: Identifiable {
    case markup
    case signature
    case crop

    var id: Int { hashValue }

    var title: String {
        switch self {
        case .markup:    return "Markup"
        case .signature: return "Signature"
        case .crop:      return "Crop"
        }
    }
}

/// SwiftUI wrapper around the UIKit markup editor.
struct MarkupEditorView: UIViewControllerRepresentable {
    let url: URL
    let mode: MarkupMode
    let onSave: (URL) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UINavigationController {
        let editor = MarkupEditorViewController(url: url, mode: mode)
        editor.onSave = onSave
        editor.onCancel = onCancel
        return UINavigationController(rootViewController: editor)
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}

// MARK: - Editor View Controller

final class MarkupEditorViewController: UIViewController {

    private let url: URL
    private let mode: MarkupMode
    var onSave: ((URL) -> Void)?
    var onCancel: (() -> Void)?

    private let imageView = UIImageView()
    private let canvasView = PKCanvasView()
    private let toolPicker = PKToolPicker()
    private var cropBox: CropSelectionView?
    private var signatureStamp: SignatureStampView?
    private var signatureContainer: UIView?

    private var pageImage: UIImage?
    private var didSetup = false

    init(url: URL, mode: MarkupMode) {
        self.url = url
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = mode.title

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: self, action: #selector(doneTapped))

        pageImage = renderFirstPage()

        imageView.image = pageImage
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)

        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(canvasView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            canvasView.topAnchor.constraint(equalTo: imageView.topAnchor),
            canvasView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            canvasView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didSetup else { return }
        didSetup = true

        switch mode {
        case .crop:      setupCrop()
        case .signature: presentSignaturePad()
        case .markup:    setupDrawing()
        }
    }

    // MARK: Setup

    private func setupDrawing() {
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
        canvasView.tool = PKInkingTool(.pen, color: .systemBlue, width: 5)
    }

    /// Native-style crop: a frame with corner handles + thirds grid over the page.
    private func setupCrop() {
        canvasView.isHidden = true
        guard let pageImage else { return }

        let imageRect = fittedRect(imageSize: pageImage.size, in: canvasView.bounds.size)
        let box = CropSelectionView(frame: canvasView.frame, imageRect: imageRect)
        view.addSubview(box)
        cropBox = box
    }

    // MARK: Signature

    /// Presents a signature pad; the drawn signature becomes a movable stamp.
    private func presentSignaturePad() {
        canvasView.isHidden = true
        let pad = SignaturePadViewController()
        pad.onComplete = { [weak self] signature in
            self?.dismiss(animated: true) {
                guard let self, let signature else {
                    self?.onCancel?()
                    return
                }
                self.addSignatureStamp(signature)
            }
        }
        let nav = UINavigationController(rootViewController: pad)
        nav.modalPresentationStyle = .formSheet
        nav.isModalInPresentation = true
        present(nav, animated: true)
    }

    private func addSignatureStamp(_ image: UIImage) {
        // Plain overlay (not the PKCanvasView, which would intercept pan/pinch).
        let container = UIView(frame: canvasView.frame)
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.backgroundColor = .clear
        // Pinch anywhere on the page resizes the signature — works even when the
        // stamp is small (two fingers don't have to land inside it).
        container.addGestureRecognizer(
            UIPinchGestureRecognizer(target: self, action: #selector(handleSignaturePinch(_:))))
        view.addSubview(container)
        signatureContainer = container

        let maxWidth: CGFloat = min(240, view.bounds.width * 0.6)
        let ratio = image.size.height / max(image.size.width, 1)
        let size = CGSize(width: maxWidth, height: maxWidth * ratio)
        let stamp = SignatureStampView(image: image)
        stamp.frame = CGRect(
            x: (container.bounds.width - size.width) / 2,
            y: (container.bounds.height - size.height) / 2,
            width: size.width, height: size.height)
        container.addSubview(stamp)
        signatureStamp = stamp
    }

    @objc private func handleSignaturePinch(_ g: UIPinchGestureRecognizer) {
        guard g.state == .changed else { return }
        signatureStamp?.applyScale(g.scale)
        g.scale = 1
    }

    // MARK: Actions

    @objc private func cancelTapped() {
        onCancel?()
    }

    @objc private func doneTapped() {
        switch mode {
        case .crop:      saveCrop()
        case .signature: saveSignature()
        case .markup:    saveMarkup()
        }
    }

    private func saveMarkup() {
        guard let flattened = flattenedDrawing() else { onCancel?(); return }
        save(image: flattened)
    }

    private func saveSignature() {
        guard let pageImage, let stamp = signatureStamp, let stampImage = stamp.image else {
            onCancel?(); return
        }

        let containerSize = signatureContainer?.bounds.size ?? canvasView.bounds.size
        let fit = fittedRect(imageSize: pageImage.size, in: containerSize)
        let scaleX = pageImage.size.width / fit.width
        let scaleY = pageImage.size.height / fit.height
        let frame = stamp.frame
        let target = CGRect(
            x: (frame.minX - fit.minX) * scaleX,
            y: (frame.minY - fit.minY) * scaleY,
            width: frame.width * scaleX,
            height: frame.height * scaleY)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let result = UIGraphicsImageRenderer(size: pageImage.size, format: format).image { _ in
            pageImage.draw(in: CGRect(origin: .zero, size: pageImage.size))
            stampImage.draw(in: target)
        }
        save(image: result)
    }

    private func saveCrop() {
        guard let pageImage, let box = cropBox else { onCancel?(); return }

        let fit = fittedRect(imageSize: pageImage.size, in: box.bounds.size)
        let selection = box.selectedRect.intersection(fit)

        guard !selection.isNull, selection.width > 10, selection.height > 10 else {
            onCancel?()
            return
        }

        let scaleX = pageImage.size.width / fit.width
        let scaleY = pageImage.size.height / fit.height
        let imageRect = CGRect(
            x: (selection.minX - fit.minX) * scaleX,
            y: (selection.minY - fit.minY) * scaleY,
            width: selection.width * scaleX,
            height: selection.height * scaleY)

        guard let cg = pageImage.cgImage?.cropping(to: imageRect) else { onCancel?(); return }
        save(image: UIImage(cgImage: cg))
    }

    private func save(image: UIImage) {
        let data = PDFConverter.makePDF(from: [image])
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("markup-\(UUID().uuidString).pdf")
        do {
            try data.write(to: tmp)
            onSave?(tmp)
        } catch {
            print("Markup save failed: \(error)")
            onCancel?()
        }
    }

    // MARK: Rendering helpers

    /// Composites the PencilKit drawing on top of the page image at full resolution.
    private func flattenedDrawing() -> UIImage? {
        guard let pageImage else { return nil }

        let boundsSize = canvasView.bounds.size
        guard boundsSize.width > 0, boundsSize.height > 0 else { return pageImage }

        let fit = fittedRect(imageSize: pageImage.size, in: boundsSize)
        let scale = UITraitCollection.current.displayScale
        let drawing = canvasView.drawing.image(
            from: CGRect(origin: .zero, size: boundsSize), scale: scale)

        // pageImage.size is already in pixels — render at scale 1 so we don't
        // allocate a bitmap multiplied by the screen scale (OOM on big scans).
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: pageImage.size, format: format)
        return renderer.image { _ in
            pageImage.draw(in: CGRect(origin: .zero, size: pageImage.size))

            if let cg = drawing.cgImage {
                let cropRect = CGRect(
                    x: fit.minX * scale,
                    y: fit.minY * scale,
                    width: fit.width * scale,
                    height: fit.height * scale)
                if let cropped = cg.cropping(to: cropRect) {
                    UIImage(cgImage: cropped).draw(
                        in: CGRect(origin: .zero, size: pageImage.size))
                }
            }
        }
    }

    /// The aspect-fit rectangle of an image within a given bounds size.
    private func fittedRect(imageSize: CGSize, in bounds: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return .zero }
        let scale = min(bounds.width / imageSize.width, bounds.height / imageSize.height)
        let w = imageSize.width * scale
        let h = imageSize.height * scale
        return CGRect(x: (bounds.width - w) / 2, y: (bounds.height - h) / 2, width: w, height: h)
    }

    /// Largest dimension (in pixels) we ever render a page at. Keeps peak
    /// memory bounded so flattening/cropping can't trigger an OOM kill.
    private let maxRenderDimension: CGFloat = 2400

    private func renderFirstPage() -> UIImage? {
        if let doc = PDFDocument(url: url), let page = doc.page(at: 0) {
            let bounds = page.bounds(for: .mediaBox)
            let target = cappedSize(for: bounds.size, maxDimension: maxRenderDimension)
            return page.thumbnail(of: target, for: .mediaBox)
        }
        if let image = UIImage(contentsOfFile: url.path) {
            return downscaled(image, maxDimension: maxRenderDimension)
        }
        return nil
    }

    /// Scales a size so its longest edge is at most `maxDimension`, but never
    /// upscales small pages beyond 2× (for crispness).
    private func cappedSize(for size: CGSize, maxDimension: CGFloat) -> CGSize {
        let longest = max(size.width, size.height)
        guard longest > 0 else { return size }
        let factor = min(2.0, maxDimension / longest)
        return CGSize(width: size.width * factor, height: size.height * factor)
    }

    /// Caps an image's largest dimension to keep memory use bounded for big scans.
    private func downscaled(_ image: UIImage, maxDimension: CGFloat = 3000) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > maxDimension else { return image }

        let factor = maxDimension / longest
        let newSize = CGSize(width: image.size.width * factor,
                             height: image.size.height * factor)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - Crop Selection Overlay

/// A native-style crop overlay: a draggable/resizable frame with real corner
/// handle views, a rule-of-thirds grid, and a dimmed area outside the selection.
final class CropSelectionView: UIView, UIGestureRecognizerDelegate {

    private(set) var selectedRect: CGRect = .zero {
        didSet { setNeedsDisplay(); layoutHandles() }
    }

    /// The bounds of the displayed page image — the selection is clamped to this.
    private let imageRect: CGRect
    private let minSize: CGFloat = 60
    private let handleSize: CGFloat = 30

    // Index order: 0 = top-left, 1 = top-right, 2 = bottom-left, 3 = bottom-right.
    private var handles: [UIView] = []

    init(frame: CGRect, imageRect: CGRect) {
        self.imageRect = imageRect
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false

        // A pan on the body moves the whole box (handles take priority).
        let movePan = UIPanGestureRecognizer(target: self, action: #selector(moveBox(_:)))
        movePan.delegate = self
        addGestureRecognizer(movePan)

        // Four draggable corner knobs.
        for index in 0..<4 {
            let knob = makeHandle()
            knob.tag = index
            let pan = UIPanGestureRecognizer(target: self, action: #selector(resizeBox(_:)))
            knob.addGestureRecognizer(pan)
            addSubview(knob)
            handles.append(knob)
        }

        selectedRect = imageRect.insetBy(dx: imageRect.width * 0.08,
                                         dy: imageRect.height * 0.08)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func makeHandle() -> UIView {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: handleSize, height: handleSize))
        v.backgroundColor = .white
        v.layer.cornerRadius = handleSize / 2
        v.layer.borderColor = UIColor.systemBlue.cgColor
        v.layer.borderWidth = 2
        return v
    }

    private func layoutHandles() {
        guard handles.count == 4 else { return }
        let r = selectedRect
        handles[0].center = CGPoint(x: r.minX, y: r.minY)
        handles[1].center = CGPoint(x: r.maxX, y: r.minY)
        handles[2].center = CGPoint(x: r.minX, y: r.maxY)
        handles[3].center = CGPoint(x: r.maxX, y: r.maxY)
    }

    // MARK: Gestures

    @objc private func moveBox(_ g: UIPanGestureRecognizer) {
        let t = g.translation(in: self)
        var r = selectedRect
        r.origin.x = min(max(r.origin.x + t.x, imageRect.minX), imageRect.maxX - r.width)
        r.origin.y = min(max(r.origin.y + t.y, imageRect.minY), imageRect.maxY - r.height)
        selectedRect = r
        g.setTranslation(.zero, in: self)
    }

    @objc private func resizeBox(_ g: UIPanGestureRecognizer) {
        guard let knob = g.view else { return }
        let t = g.translation(in: self)
        let r = selectedRect

        switch knob.tag {
        case 0: selectedRect = rect(minX: r.minX + t.x, minY: r.minY + t.y, maxX: r.maxX, maxY: r.maxY)
        case 1: selectedRect = rect(minX: r.minX, minY: r.minY + t.y, maxX: r.maxX + t.x, maxY: r.maxY)
        case 2: selectedRect = rect(minX: r.minX + t.x, minY: r.minY, maxX: r.maxX, maxY: r.maxY + t.y)
        case 3: selectedRect = rect(minX: r.minX, minY: r.minY, maxX: r.maxX + t.x, maxY: r.maxY + t.y)
        default: break
        }
        g.setTranslation(.zero, in: self)
    }

    /// Builds a clamped rect from edges, enforcing image bounds + min size.
    private func rect(minX: CGFloat, minY: CGFloat, maxX: CGFloat, maxY: CGFloat) -> CGRect {
        let left = max(min(minX, maxX - minSize), imageRect.minX)
        let top = max(min(minY, maxY - minSize), imageRect.minY)
        let right = min(max(maxX, left + minSize), imageRect.maxX)
        let bottom = min(max(maxY, top + minSize), imageRect.maxY)
        return CGRect(x: left, y: top, width: right - left, height: bottom - top)
    }

    // Don't let the body's move pan steal touches that land on a corner knob.
    func gestureRecognizer(_ g: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let v = touch.view, handles.contains(v) { return false }
        return true
    }

    // MARK: Drawing

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        // Dim everything outside the selection.
        ctx.setFillColor(UIColor.black.withAlphaComponent(0.5).cgColor)
        ctx.fill(rect)
        ctx.setBlendMode(.clear)
        ctx.fill(selectedRect)
        ctx.setBlendMode(.normal)

        // Frame border.
        ctx.setStrokeColor(UIColor.white.cgColor)
        ctx.setLineWidth(1.5)
        ctx.stroke(selectedRect)

        // Rule-of-thirds grid.
        ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.5).cgColor)
        ctx.setLineWidth(0.5)
        for i in 1...2 {
            let x = selectedRect.minX + selectedRect.width * CGFloat(i) / 3
            let y = selectedRect.minY + selectedRect.height * CGFloat(i) / 3
            ctx.move(to: CGPoint(x: x, y: selectedRect.minY))
            ctx.addLine(to: CGPoint(x: x, y: selectedRect.maxY))
            ctx.move(to: CGPoint(x: selectedRect.minX, y: y))
            ctx.addLine(to: CGPoint(x: selectedRect.maxX, y: y))
        }
        ctx.strokePath()
    }
}

// MARK: - Signature Stamp

/// A draggable, pinch-to-resize signature image placed on the document.
final class SignatureStampView: UIView {

    let image: UIImage?
    private let imageView = UIImageView()
    private let aspect: CGFloat
    private let minWidth: CGFloat = 40

    init(image: UIImage) {
        self.image = image
        self.aspect = image.size.height / max(image.size.width, 1)
        super.init(frame: .zero)
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.frame = bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(imageView)
        layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.8).cgColor
        layer.borderWidth = 1

        isUserInteractionEnabled = true

        let pan = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
        addGestureRecognizer(pan)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func pan(_ g: UIPanGestureRecognizer) {
        guard let parent = superview else { return }
        let t = g.translation(in: parent)
        center = CGPoint(x: center.x + t.x, y: center.y + t.y)
        g.setTranslation(.zero, in: parent)
    }

    /// Resizes by a pinch scale, keeping the center and aspect ratio.
    /// Called from the parent overlay so a small stamp is still easy to resize.
    func applyScale(_ scale: CGFloat) {
        guard let parent = superview else { return }
        var newWidth = bounds.width * scale
        newWidth = max(minWidth, min(newWidth, parent.bounds.width))
        let newHeight = newWidth * aspect

        let savedCenter = center
        bounds = CGRect(x: 0, y: 0, width: newWidth, height: newHeight)
        center = savedCenter
    }
}

// MARK: - Signature Pad

/// A simple full-screen pad for drawing a signature, returning a trimmed image.
final class SignaturePadViewController: UIViewController {

    var onComplete: ((UIImage?) -> Void)?

    private let canvasView = PKCanvasView()
    private let toolPicker = PKToolPicker()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Sign"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done)),
            UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clear)),
        ]

        canvasView.backgroundColor = .secondarySystemBackground
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 4)
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(canvasView)

        let prompt = UILabel()
        prompt.text = "Sign here"
        prompt.textColor = .tertiaryLabel
        prompt.font = .systemFont(ofSize: 17)
        prompt.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(prompt)

        NSLayoutConstraint.activate([
            canvasView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            canvasView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            canvasView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            canvasView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            prompt.centerXAnchor.constraint(equalTo: canvasView.centerXAnchor),
            prompt.centerYAnchor.constraint(equalTo: canvasView.centerYAnchor),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
    }

    @objc private func cancel() { onComplete?(nil) }

    @objc private func clear() { canvasView.drawing = PKDrawing() }

    @objc private func done() {
        let inkBounds = canvasView.drawing.bounds
        guard !inkBounds.isNull, inkBounds.width > 2, inkBounds.height > 2 else {
            onComplete?(nil)
            return
        }
        let signature = canvasView.drawing.image(from: inkBounds, scale: UITraitCollection.current.displayScale)
        onComplete?(signature)
    }
}
