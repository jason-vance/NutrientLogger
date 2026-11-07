//
//  BarcodeScannerView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/22/26.
//

import SwiftUI
import AVFoundation

struct BarcodeScannerView: UIViewControllerRepresentable {

    let onBarcodeDetected: (String) -> Void

    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        let vc = BarcodeScannerViewController()
        vc.onBarcodeDetected = onBarcodeDetected
        return vc
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerViewController, context: Context) {}
}

class BarcodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    var onBarcodeDetected: ((String) -> Void)?

    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    // Keeps the camera image upright however the screen is turned, including the unfolded
    // iPhone Duo, whose inner display is landscape even though the app is portrait only.
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
    private var rotationObservation: NSKeyValueObservation?
    private var hasDetected = false

    private let cutoutView = UIView()
    private let overlayLayer = CAShapeLayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
        setupOverlay()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        updateOverlay()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hasDetected = false
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
    }

    private func setupCamera() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        let output = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.ean8, .ean13, .upce]
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)

        let coordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: previewLayer)
        rotationCoordinator = coordinator
        applyPreviewRotation()
        rotationObservation = coordinator.observe(\.videoRotationAngleForHorizonLevelPreview) { [weak self] _, _ in
            DispatchQueue.main.async { self?.applyPreviewRotation() }
        }
    }

    private func applyPreviewRotation() {
        guard let angle = rotationCoordinator?.videoRotationAngleForHorizonLevelPreview,
              let connection = previewLayer?.connection,
              connection.isVideoRotationAngleSupported(angle) else { return }
        connection.videoRotationAngle = angle
    }

    private func setupOverlay() {
        overlayLayer.fillRule = .evenOdd
        overlayLayer.fillColor = UIColor.black.withAlphaComponent(0.5).cgColor
        view.layer.addSublayer(overlayLayer)

        let cutoutBorder = CAShapeLayer()
        cutoutBorder.strokeColor = UIColor.white.withAlphaComponent(0.8).cgColor
        cutoutBorder.fillColor = UIColor.clear.cgColor
        cutoutBorder.lineWidth = 2
        view.layer.addSublayer(cutoutBorder)

        self.cutoutBorderLayer = cutoutBorder
    }

    private var cutoutBorderLayer: CAShapeLayer?

    private var scanRect: CGRect {
        // A barcode-shaped window; on wide screens it stays barcode-sized instead of spanning the view.
        let width = min(view.bounds.width * 0.75, 360)
        let height: CGFloat = 200
        return CGRect(
            x: (view.bounds.width - width) / 2,
            y: (view.bounds.height - height) / 2 - 40,
            width: width,
            height: height
        )
    }

    private func updateOverlay() {
        let fullPath = UIBezierPath(rect: view.bounds)
        let cutoutPath = UIBezierPath(roundedRect: scanRect, cornerRadius: 12)
        fullPath.append(cutoutPath)
        overlayLayer.path = fullPath.cgPath

        cutoutBorderLayer?.path = cutoutPath.cgPath
        cutoutBorderLayer?.frame = view.bounds
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !hasDetected,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let barcode = object.stringValue else {
            return
        }

        hasDetected = true
        captureSession.stopRunning()

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        onBarcodeDetected?(barcode)
    }

    func resetScanner() {
        hasDetected = false
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }
}
