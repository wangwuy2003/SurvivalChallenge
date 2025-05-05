import UIKit
import AVFoundation
import Vision
import Stevia

class TestVC: UIViewController {
    private var captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private let eyebrowImageView = UIImageView()
    private let faceDetectionQueue = DispatchQueue(label: "faceDetectionQueue")
    
    // Các biến để làm mượt vị trí
    private var previousLeftEyePoint: CGPoint?
    private var previousRightEyePoint: CGPoint?
    private var smoothingFactor: CGFloat = 0.85  // Tăng cao để cực kỳ ổn định
    
    // Các cài đặt cố định
    private let fixedImageWidth: CGFloat = 220  // Chiều rộng cố định
    private let eyebrowOffsetY: CGFloat = 30    // Khoảng cách từ mắt lên lông mày
    private let imageOffsetY: CGFloat = 0     // Khoảng cách từ lông mày tới ảnh
    
    // Debug
    private let statusLabel = UILabel()
    private let leftEyeMarker = UIView()
    private let rightEyeMarker = UIView()
    private let debugMode = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        setupCamera()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }
    
    private func startSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }
    
    private func stopSession() {
        captureSession.stopRunning()
    }
    
    private func setupUI() {
        // Status label
        statusLabel.textColor = .white
        statusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        statusLabel.textAlignment = .center
        statusLabel.font = UIFont.systemFont(ofSize: 14)
        statusLabel.text = "Waiting for camera..."
        view.addSubview(statusLabel)
        statusLabel.frame = CGRect(x: 10, y: 50, width: view.bounds.width - 20, height: 30)
        
        // Back button
        let backButton = UIButton(type: .system)
        backButton.setTitle("Back", for: .normal)
        backButton.setTitleColor(.white, for: .normal)
        backButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        backButton.layer.cornerRadius = 8
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        view.addSubview(backButton)
        backButton.frame = CGRect(x: 10, y: 10, width: 60, height: 30)
        
        // Create test image
        createTestImage()
        
        // Setup eyebrow image view
        eyebrowImageView.contentMode = .scaleAspectFit
        eyebrowImageView.isHidden = true
        view.addSubview(eyebrowImageView)
        
        // Debug markers
        if debugMode {
            leftEyeMarker.backgroundColor = UIColor.red.withAlphaComponent(0.5)
            leftEyeMarker.frame = CGRect(x: 0, y: 0, width: 10, height: 10)
            leftEyeMarker.layer.cornerRadius = 5
            
            rightEyeMarker.backgroundColor = UIColor.green.withAlphaComponent(0.5)
            rightEyeMarker.frame = CGRect(x: 0, y: 0, width: 10, height: 10)
            rightEyeMarker.layer.cornerRadius = 5
            
            view.addSubview(leftEyeMarker)
            view.addSubview(rightEyeMarker)
        }
        
        // Bring UI elements to front
        view.bringSubviewToFront(statusLabel)
        view.bringSubviewToFront(backButton)
    }
    
    private func createTestImage() {
        // Create a bright, distinctive test image
        let size = CGSize(width: 300, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        // Draw gradient background
        let context = UIGraphicsGetCurrentContext()!
        let colors = [UIColor.red.cgColor, UIColor.blue.cgColor] as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let locations: [CGFloat] = [0.0, 1.0]
        
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
            context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: size.width, y: 0), options: [])
        }
        
        // Draw white border
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(5)
        context.stroke(CGRect(x: 5, y: 5, width: size.width - 10, height: size.height - 10))
        
        // Draw text
        let text = "TEST IMAGE"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 40),
            .foregroundColor: UIColor.white,
            .strokeColor: UIColor.black,
            .strokeWidth: -3.0
        ]
        
        let textSize = text.size(withAttributes: attributes)
        let rect = CGRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        text.draw(in: rect, withAttributes: attributes)
        
        // Get image from context
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        eyebrowImageView.image = image
        
        // Preview image
        let previewImageView = UIImageView(image: image)
        previewImageView.contentMode = .scaleAspectFit
        previewImageView.layer.borderColor = UIColor.white.cgColor
        previewImageView.layer.borderWidth = 1
        view.addSubview(previewImageView)
        previewImageView.frame = CGRect(x: view.bounds.width - 80, y: view.bounds.height - 50, width: 70, height: 40)
    }
    
    private func setupCamera() {
        updateStatus("Setting up camera...")
        
        // Check camera permission
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.configureCaptureSession()
                    }
                } else {
                    self.updateStatus("Camera access denied")
                }
            }
        case .denied, .restricted:
            updateStatus("Camera access denied")
        @unknown default:
            updateStatus("Unknown camera status")
        }
    }
    
    private func configureCaptureSession() {
        captureSession.beginConfiguration()
        
        // Set quality
        if captureSession.canSetSessionPreset(.high) {
            captureSession.sessionPreset = .high
        }
        
        // Setup input
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else {
            updateStatus("Failed to access camera")
            captureSession.commitConfiguration()
            return
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        } else {
            updateStatus("Failed to add camera input")
            captureSession.commitConfiguration()
            return
        }
        
        // Setup output
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: faceDetectionQueue)
        output.alwaysDiscardsLateVideoFrames = true
        
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
        } else {
            updateStatus("Failed to add camera output")
            captureSession.commitConfiguration()
            return
        }
        
        // Set orientation
        if let connection = output.connection(with: .video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = true
            }
        }
        
        captureSession.commitConfiguration()
        
        // Setup preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
        
        updateStatus("Camera ready")
    }
    
    private func updateEyebrowPosition(for face: VNFaceObservation) {
        guard let leftEye = face.landmarks?.leftEye,
              let rightEye = face.landmarks?.rightEye else {
            return
        }
        
        // Convert normalized coordinates to view coordinates
        let viewBounds = view.bounds
        let transform = CGAffineTransform(
            scaleX: viewBounds.width,
            y: viewBounds.height
        )
        
        // Flip y-axis (Vision uses bottom-left origin, UIKit uses top-left)
        let flipYTransform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1)
        let combinedTransform = flipYTransform.concatenating(transform)
        
        let leftEyePoints = leftEye.normalizedPoints.map { $0.applying(combinedTransform) }
        let rightEyePoints = rightEye.normalizedPoints.map { $0.applying(combinedTransform) }
        
        // Calculate midpoint between eyes
        let leftEyeCenter = leftEyePoints.reduce(CGPoint.zero, +) / CGFloat(leftEyePoints.count)
        let rightEyeCenter = rightEyePoints.reduce(CGPoint.zero, +) / CGFloat(rightEyePoints.count)
        
        // Apply smoothing to eye positions for stability
        var smoothedLeftEye = leftEyeCenter
        var smoothedRightEye = rightEyeCenter
        
        if let prevLeft = previousLeftEyePoint, let prevRight = previousRightEyePoint {
            smoothedLeftEye = CGPoint(
                x: prevLeft.x * smoothingFactor + leftEyeCenter.x * (1 - smoothingFactor),
                y: prevLeft.y * smoothingFactor + leftEyeCenter.y * (1 - smoothingFactor)
            )
            
            smoothedRightEye = CGPoint(
                x: prevRight.x * smoothingFactor + rightEyeCenter.x * (1 - smoothingFactor),
                y: prevRight.y * smoothingFactor + rightEyeCenter.y * (1 - smoothingFactor)
            )
        }
        
        // Save for next frame
        previousLeftEyePoint = smoothedLeftEye
        previousRightEyePoint = smoothedRightEye
        
        // Calculate center between eyes
        let eyesCenter = CGPoint(
            x: (smoothedLeftEye.x + smoothedRightEye.x) / 2,
            y: (smoothedLeftEye.y + smoothedRightEye.y) / 2
        )
        
        // Update debug markers if needed
        if debugMode {
            DispatchQueue.main.async {
                self.leftEyeMarker.center = smoothedLeftEye
                self.rightEyeMarker.center = smoothedRightEye
            }
        }
        
        // Calculate the fixed height based on the fixed width and aspect ratio
        let aspectRatio = (eyebrowImageView.image?.size.height ?? 1) / (eyebrowImageView.image?.size.width ?? 1)
        let fixedImageHeight = fixedImageWidth * aspectRatio
        
        let eyeY = min(smoothedLeftEye.y, smoothedRightEye.y)
        // Tính toán vị trí chính xác của lông mày (eyebrowOffsetY pixel phía trên mắt)
        let eyebrowY = eyeY - eyebrowOffsetY
        // Đặt ảnh chính xác tại vị trí lông mày
        let imageY = eyebrowY - fixedImageHeight

        // Create new position with fixed width
        let newPosition = CGRect(
            x: eyesCenter.x - fixedImageWidth / 2,
            y: imageY,  // Đặt ảnh trực tiếp ở vị trí lông mày
            width: fixedImageWidth,
            height: fixedImageHeight
        )
        
        // Update UI on main thread
        DispatchQueue.main.async {
            // Update status
            self.updateStatus("Face detected")
            
            // Update eyebrow position with slow animation for stability
            UIView.animate(withDuration: 0.3, delay: 0, options: .beginFromCurrentState) {
                self.eyebrowImageView.frame = newPosition
            }
            
            // Show eyebrow image if hidden
            if self.eyebrowImageView.isHidden {
                self.eyebrowImageView.isHidden = false
            }
        }
    }
    
    private func updateStatus(_ message: String) {
        DispatchQueue.main.async {
            self.statusLabel.text = message
        }
    }
    
    @objc private func backButtonTapped() {
        dismiss(animated: true)
    }
}

extension TestVC: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNDetectFaceLandmarksRequest { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                self.updateStatus("Face detection error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.eyebrowImageView.isHidden = true
                }
                return
            }
            
            guard let face = request.results?.first as? VNFaceObservation else {
                // Don't hide image immediately when face disappears briefly
                if self.previousLeftEyePoint != nil && self.previousRightEyePoint != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        if request.results?.isEmpty ?? true {
                            self.eyebrowImageView.isHidden = true
                            self.updateStatus("No face detected")
                            // Reset tracking points only after delay
                            self.previousLeftEyePoint = nil
                            self.previousRightEyePoint = nil
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.eyebrowImageView.isHidden = true
                        self.updateStatus("No face detected")
                    }
                }
                return
            }
            
            self.updateEyebrowPosition(for: face)
        }
        
        // Process with Vision
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .upMirrored, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            updateStatus("Vision request failed: \(error.localizedDescription)")
        }
    }
}

extension CGPoint {
    static func + (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x + right.x, y: left.y + right.y)
    }
    
    static func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
        return CGPoint(x: point.x / scalar, y: point.y / scalar)
    }
}
