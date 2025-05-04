import UIKit
import Stevia
import AVFoundation
import MLKitFaceDetection
import MLKit
import SDWebImage
import CoreImage

class GuessView: UIView, AVCaptureVideoDataOutputSampleBufferDelegate {
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var meView: UIView!
    @IBOutlet weak var myBoyView: UIView!
    @IBOutlet weak var meImage: UIImageView!
    @IBOutlet weak var myBoyImage: UIImageView!
    @IBOutlet weak var contentImageView: UIView!
    
    var designType: DesignType = .guessType
    
    private var session: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var isUsingFrontCamera = true
    
    private var detectionLayer: CALayer?
    private var scanningLineLayer: CALayer?
    private var isScanning = false
    private var hasCompletedGuess = false
    private var guessImageURLs: (me: [String], myBoy: [String]) = ([], [])
    private var selectedGuessImages: (me: String?, myBoy: String?) = (nil, nil)
    private var isActive = false
    private var isProcessing = false
    
    private let videoQueue = DispatchQueue(label: "com.nhanhoo.guess.videoQueue", qos: .userInteractive)
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    
    private let previewImageView = UIImageView()
    
    // MARK: - Initialization
    override func awakeFromNib() {
        super.awakeFromNib()
        print("yolo GuessView awakeFromNib called")
        setupView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadFileXib()
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadFileXib()
        setupView()
    }
    
    deinit {
        deactivate()
        print("⚙️ deinit (Self.self)")
    }
    
    // MARK: - Setup
    func loadFileXib() {
        Bundle.main.loadNibNamed("GuessView", owner: self, options: nil)
        self.addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func setupView() {
        // Kiểm tra outlets để tránh crash
        if let meView = meView, let myBoyView = myBoyView {
            meView.borderColor = .hexED0384
            meView.borderWidth = 4
            
            myBoyView.borderColor = .hexED0384
            myBoyView.borderWidth = 4
        }
        
        // Setup preview image view
        previewImageView.contentMode = .scaleAspectFill
        previewImageView.clipsToBounds = true
        
        // Insert preview image view at index 0 (bottom-most position)
        insertSubview(previewImageView, at: 0)
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            previewImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            previewImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            previewImageView.topAnchor.constraint(equalTo: topAnchor),
            previewImageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        if let contentView = contentView {
            bringSubviewToFront(contentView)
        }
        
        if let contentImageView = contentImageView {
            bringSubviewToFront(contentImageView)
        }
    }
    
    // MARK: - Public Methods
    func activate() {
        isActive = true
    }
    
    func deactivate() {
        isActive = false
        if let videoOutput = videoOutput {
            videoOutput.setSampleBufferDelegate(nil, queue: nil)
        }
        stopScanning()
        session = nil
        videoOutput = nil
        DispatchQueue.main.async {
            self.previewImageView.image = nil
        }
    }
    
    func setPreviewSession(_ session: AVCaptureSession?, _ isFrontCamera: Bool) {
        guard let session = session else { return }
        self.session = session
        self.isUsingFrontCamera = isFrontCamera
        
        isProcessing = true
        
        if let existingOutput = videoOutput {
            session.removeOutput(existingOutput)
        }
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: videoQueue)
        
        if session.canAddOutput(output) {
            session.addOutput(output)
            videoOutput = output
        }
    }
    
    func setChallenge(_ challenge: SurvivalChallengeEntity?) {
        guard let challenge = challenge else {
            resetState()
            return
        }
        
        guessImageURLs.me = challenge.imgOptionUrl.filter { $0.contains("/Nu/") }
        guessImageURLs.myBoy = challenge.imgOptionUrl.filter { $0.contains("/Nam/") }
        print("yolo Guess filter - Female images: (guessImageURLs.me.count), Male images: (guessImageURLs.myBoy.count) for challenge: (challenge.name)")
        
        for url in guessImageURLs.me + guessImageURLs.myBoy {
            if let url = URL(string: url) {
                SDWebImageDownloader.shared.downloadImage(with: url, options: [.preloadAllFrames, .scaleDownLargeImages], progress: nil) { (image, _, error, _) in
                    if let error = error {
                        print("Failed to preload image (url): (error.localizedDescription)")
                    } else {
                        print("Preloaded image: (url)")
                    }
                }
            }
        }
        
        resetState()
    }
    
    func resetState() {
        isScanning = false
        hasCompletedGuess = false
        selectedGuessImages = (nil, nil)
        resetImages()
        stopScanning()
        detectionLayer?.sublayers?.removeAll()
        scanningLineLayer?.removeFromSuperlayer()
        scanningLineLayer = nil
        print("yolo GuessView state reset")
    }
    
    // MARK: - UI Methods
    func resetImages() {
        if let meImage = meImage, let myBoyImage = myBoyImage {
            meImage.image = UIImage(named: "squidgame")
            myBoyImage.image = UIImage(named: "squidgame")
            meImage.alpha = 1
            myBoyImage.alpha = 1
            print("yolo GuessView images reset")
        }
    }
    
    func setImages(meUrl: String?, myBoyUrl: String?) {
        guard let meImage = meImage, let myBoyImage = myBoyImage else {
            print("Error: Image views are nil in setImages")
            return
        }
        
        let defaultImage = UIImage(named: "squidgame")
        meImage.image = defaultImage
        myBoyImage.image = defaultImage
        
        if let meUrl = meUrl, let url = URL(string: meUrl) {
            meImage.sd_setImage(with: url, placeholderImage: defaultImage) { [weak self] (image, error, _, _) in
                if let error = error {
                    print("yolo Failed to load meImage: (error.localizedDescription)")
                } else {
                    print("yolo Loaded meImage: (meUrl)")
                    self?.meImage?.alpha = 0
                    UIView.animate(withDuration: 0.3) {
                        self?.meImage?.alpha = 1
                    }
                }
            }
        }
        
        if let myBoyUrl = myBoyUrl, let url = URL(string: myBoyUrl) {
            myBoyImage.sd_setImage(with: url, placeholderImage: defaultImage) { [weak self] (image, error, _, _) in
                if let error = error {
                    print("yolo Failed to load myBoyImage: (error.localizedDescription)")
                } else {
                    print("yolo Loaded myBoyImage: (myBoyUrl)")
                    self?.myBoyImage?.alpha = 0
                    UIView.animate(withDuration: 0.3) {
                        self?.myBoyImage?.alpha = 1
                    }
                }
            }
        }
    }
    
    // MARK: - Face Detection
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isActive, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let imageWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let imageHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let imageSize = CGSize(width: imageWidth, height: imageHeight)
        
        // Convert sample buffer to UIImage for preview
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let orientedImage = isUsingFrontCamera ? ciImage.oriented(.leftMirrored) : ciImage.oriented(.right)
        if let cgImage = ciContext.createCGImage(orientedImage, from: orientedImage.extent) {
            let uiImage = UIImage(cgImage: cgImage)
            DispatchQueue.main.async { [weak self] in
                self?.previewImageView.image = uiImage
            }
        }
        
        let visionImage = VisionImage(buffer: sampleBuffer)
        visionImage.orientation = imageOrientation()
        
        faceDetection(image: visionImage, imageSize: imageSize)
    }
    
    private func imageOrientation() -> UIImage.Orientation {
        let deviceOrientation = UIDevice.current.orientation
        switch (isUsingFrontCamera, deviceOrientation) {
        case (true, .landscapeLeft): return .upMirrored
        case (true, .landscapeRight): return .downMirrored
        case (true, .portraitUpsideDown): return .leftMirrored
        case (true, _): return .rightMirrored
        case (false, .landscapeLeft): return .down
        case (false, .landscapeRight): return .up
        case (false, .portraitUpsideDown): return .right
        case (false, _): return .left
        }
    }
    
    private func faceDetection(image: VisionImage, imageSize: CGSize) {
        if detectionLayer == nil {
            DispatchQueue.main.async { [weak self] in
                guard let self = self, self.window != nil else { return }
                self.setupDetectionLayer()
            }
        }
        
        let options = FaceDetectorOptions()
        options.performanceMode = .accurate
        options.landmarkMode = .all
        options.classificationMode = .all
        
        let faceDetector = FaceDetector.faceDetector(options: options)
        
        faceDetector.process(image) { [weak self] faces, error in
            guard let self = self, self.isActive, self.window != nil else { return }
            
            if let error = error {
                print("Lỗi khi nhận diện khuôn mặt: (error.localizedDescription)")
                return
            }
            
            guard let faces = faces, !faces.isEmpty else {
                DispatchQueue.main.async {
                    self.detectionLayer?.sublayers?.removeAll(keepingCapacity: false)
                    self.scanningLineLayer?.isHidden = true
                    self.isScanning = false
                    print("Không tìm thấy khuôn mặt")
                }
                return
            }
            
            print("Found (faces.count) face(s)")
            DispatchQueue.main.async {
                for face in faces {
                    self.handleGuessFaceDetection(face, imageSize: imageSize)
                }
            }
        }
    }
    
    private func handleGuessFaceDetection(_ face: Face, imageSize: CGSize) {
        let faceFrame = convertToViewCoordinates(face.frame, imageSize: imageSize)
        
        if !isScanning && !hasCompletedGuess && faceFrame.width > 50 {
            startScanning(faceFrame: faceFrame)
        }
        
        detectionLayer?.sublayers?.forEach {
            if $0 != scanningLineLayer {
                $0.removeFromSuperlayer()
            }
        }
    }
    
    private func convertToViewCoordinates(_ rect: CGRect, imageSize: CGSize) -> CGRect {
        let normalizedX = rect.origin.x / imageSize.width
        let normalizedY = rect.origin.y / imageSize.height
        let normalizedWidth = rect.width / imageSize.width
        let normalizedHeight = rect.height / imageSize.height
        
        let viewWidth = bounds.width
        let viewHeight = bounds.height
        
        return CGRect(
            x: normalizedX * viewWidth,
            y: (1 - normalizedY - normalizedHeight) * viewHeight,
            width: normalizedWidth * viewWidth,
            height: normalizedHeight * viewHeight
        )
    }
    
    private func setupDetectionLayer() {
        detectionLayer?.removeFromSuperlayer()
        detectionLayer = nil
        
        detectionLayer = CALayer()
        detectionLayer?.frame = bounds
        detectionLayer?.masksToBounds = true
        
        layer.addSublayer(detectionLayer!)
        
        setupScanningLine()
        print("Detection layer initialized with dimensions: (detectionLayer?.frame ?? .zero)")
    }
    
    private func setupScanningLine() {
        scanningLineLayer?.removeFromSuperlayer()
        
        scanningLineLayer = CALayer()
        scanningLineLayer?.backgroundColor = UIColor.hexED0384.cgColor
        scanningLineLayer?.frame = CGRect(x: 0, y: 0, width: bounds.width, height: 4)
        
        if let detectionLayer = detectionLayer, let scanningLineLayer = scanningLineLayer {
            detectionLayer.addSublayer(scanningLineLayer)
        }
        
        scanningLineLayer?.isHidden = true
        print("yolo Scanning line layer initialized")
    }
    
    private func startScanning(faceFrame: CGRect) {
        guard !isScanning, !hasCompletedGuess, isActive else {
            print("yolo Scanning not started: isScanning=(isScanning), hasCompletedGuess=(hasCompletedGuess)")
            return
        }
        isScanning = true
        scanningLineLayer?.isHidden = false
        
        let faceY = faceFrame.origin.y
        let faceHeight = faceFrame.height
        let scanRange = faceHeight * 0.8
        let startY = faceY + faceHeight * 0.1
        let endY = startY + scanRange
        
        let animation = CAKeyframeAnimation(keyPath: "position.y")
        animation.values = [startY, endY, startY]
        animation.keyTimes = [0, 0.5, 1]
        animation.duration = 3.0
        animation.repeatCount = 1
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.delegate = self
        
        scanningLineLayer?.add(animation, forKey: "scanAnimation")
        print("yolo Started scanning animation")
    }
    
    private func stopScanning() {
        isScanning = false
        scanningLineLayer?.isHidden = true
        scanningLineLayer?.removeAnimation(forKey: "scanAnimation")
        print("yolo Stopped scanning")
    }
    
    private func selectGuessImages() {
        guard !guessImageURLs.me.isEmpty || !guessImageURLs.myBoy.isEmpty else {
            print("yolo selectGuessImages failed: no images available")
            return
        }
        
        selectedGuessImages.myBoy = guessImageURLs.myBoy.randomElement()
        selectedGuessImages.me = guessImageURLs.me.randomElement()
        
        setImages(meUrl: selectedGuessImages.me, myBoyUrl: selectedGuessImages.myBoy)
        hasCompletedGuess = true
    }
}

// MARK: - CAAnimationDelegate
extension GuessView: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag && isScanning && isActive {
            stopScanning()
            selectGuessImages()
        }
    }
}
