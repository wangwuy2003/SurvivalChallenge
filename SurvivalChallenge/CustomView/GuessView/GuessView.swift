//
//  GuessView.swift
//  SurvivalChallenge
//
//  Created by Apple on 21/4/25.
//

import UIKit
import Stevia
import AVFoundation
import MLKitFaceDetection
import MLKit
import SDWebImage

class GuessView: UIView, AVCaptureVideoDataOutputSampleBufferDelegate {
    @IBOutlet weak var meView: UIView!
    @IBOutlet weak var myBoyView: UIView!
    @IBOutlet weak var meImage: UIImageView!
    @IBOutlet weak var myBoyImage: UIImageView!
    
    var designType: DesignType = .guessType
    
    private var session: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var isUsingFrontCamera = true
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    private var detectionLayer: CALayer?
    private var scanningLineLayer: CALayer?
    private var isScanning = false
    private var hasCompletedGuess = false
    private var guessImageURLs: (me: [String], myBoy: [String]) = ([], [])
    private var selectedGuessImages: (me: String?, myBoy: String?) = (nil, nil)
    private var isActive = false
    private var isProcessing = false
    
    private let videoQueue = DispatchQueue(label: "com.nhanhoo.guess.videoQueue", qos: .userInteractive)
    
    // MARK: - Initialization
    override func awakeFromNib() {
        super.awakeFromNib()
        print("yolo GuessView awakeFromNib called")
        setupView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        print("yolo GuessView init(frame:) called")
        loadFromNib()
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        print("yolo GuessView init(coder:) called")
    }
    
    deinit {
        deactivate()
        print("⚙️ deicanit \(Self.self)")
    }
    
    // MARK: - Setup
    private func loadFromNib() {
        // Load view từ nib với owner là nil (không phải GuessView)
        if let contentView = Bundle.main.loadNibNamed("GuessView", owner: nil, options: nil)?.first as? UIView {
            contentView.frame = bounds
            contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(contentView)
        }
    }
    
    func setupView() {
        // Kiểm tra outlets để tránh crash
        if let meView = meView, let myBoyView = myBoyView {
            meView.borderColor = .hexED0384
            meView.borderWidth = 4
            
            myBoyView.borderColor = .hexED0384
            myBoyView.borderWidth = 4
        }
    }
    
    // MARK: - Public Methods
    func activate() {
        isActive = true
    }
    
    func deactivate() {
        isActive = false
        // Dừng xử lý và giải phóng tài nguyên
        if let videoOutput = videoOutput {
            videoOutput.setSampleBufferDelegate(nil, queue: nil)
        }
        stopScanning()
        session = nil
        videoOutput = nil
    }
    
    func setPreviewSession(_ session: AVCaptureSession?, _ isFrontCamera: Bool) {
        // Chỉ thiết lập nếu cần thiết
        guard let session = session, window != nil else {
            print("yolo \(self) setPreviewSession failed: session nil or window nil")
            return
        }
        
        print("yolo \(self) setPreviewSession starting")
        
        // Đánh dấu view đang xử lý
        isProcessing = true
        
        // Xóa delegate cũ
        if let existingOutput = videoOutput {
            existingOutput.setSampleBufferDelegate(nil, queue: nil)
            if self.session != nil {
                self.session?.removeOutput(existingOutput)
            }
        }
        
        // Đặt lại tham chiếu
        self.session = session
        self.isUsingFrontCamera = isFrontCamera
        
        // Thiết lập output với delay để tránh race condition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self, self.window != nil else { return }
            
            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: self.videoQueue)
            
            if session.canAddOutput(output) {
                session.addOutput(output)
                self.videoOutput = output
                self.isProcessing = false
                print("yolo \(self) setPreviewSession completed successfully")
                self.activate() // Đảm bảo kích hoạt view
            } else {
                print("yolo \(self) failed to add output to session")
            }
        }
    }
    
    func setChallenge(_ challenge: SurvivalChallengeEntity?) {
        guard let challenge = challenge else {
            resetState()
            return
        }
        
        guessImageURLs.me = challenge.imgOptionUrl.filter { $0.contains("/Nu/") }
        guessImageURLs.myBoy = challenge.imgOptionUrl.filter { $0.contains("/Nam/") }
        print("yolo Guess filter - Female images: \(guessImageURLs.me.count), Male images: \(guessImageURLs.myBoy.count) for challenge: \(challenge.name)")
        
        // Preload images
        for url in guessImageURLs.me + guessImageURLs.myBoy {
            if let url = URL(string: url) {
                SDWebImageDownloader.shared.downloadImage(with: url, options: [.preloadAllFrames, .scaleDownLargeImages], progress: nil) { (image, _, error, _) in
                    if let error = error {
                        print("Failed to preload image \(url): \(error.localizedDescription)")
                    } else {
                        print("Preloaded image: \(url)")
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
        // Kiểm tra nil trước khi truy cập
        if let meImage = meImage, let myBoyImage = myBoyImage {
            meImage.image = UIImage(named: "squidgame")
            myBoyImage.image = UIImage(named: "squidgame")
            meImage.alpha = 1
            myBoyImage.alpha = 1
            print("yolo GuessView images reset")
        }
    }
    
    func setImages(meUrl: String?, myBoyUrl: String?) {
        // Kiểm tra nil trước khi truy cập
        guard let meImage = meImage, let myBoyImage = myBoyImage else {
            print("Error: Image views are nil in setImages")
            return
        }
        
        // Đặt ảnh mặc định
        let defaultImage = UIImage(named: "squidgame")
        meImage.image = defaultImage
        myBoyImage.image = defaultImage
        
        if let meUrl = meUrl, let url = URL(string: meUrl) {
            meImage.sd_setImage(with: url, placeholderImage: defaultImage) { [weak self] (image, error, _, _) in
                if let error = error {
                    print("yolo Failed to load meImage: \(error.localizedDescription)")
                } else {
                    print("yolo Loaded meImage: \(meUrl)")
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
                    print("yolo Failed to load myBoyImage: \(error.localizedDescription)")
                } else {
                    print("yolo Loaded myBoyImage: \(myBoyUrl)")
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
        // Kiểm tra view có hoạt động không
        guard isActive, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let imageWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let imageHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let imageSize = CGSize(width: imageWidth, height: imageHeight)
        
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
                print("Lỗi khi nhận diện khuôn mặt: \(error.localizedDescription)")
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
            
            print("Found \(faces.count) face(s)")
            DispatchQueue.main.async {
                for face in faces {
                    self.handleGuessFaceDetection(face, imageSize: imageSize)
                }
            }
        }
    }
    
    private func handleGuessFaceDetection(_ face: Face, imageSize: CGSize) {
        guard let previewLayer = previewLayer else {
            print("Preview layer not initialized")
            return
        }
        
        let faceFrame = previewLayer.layerRectConverted(fromCaptureDeviceRect: face.frame, imageSize: imageSize)
        
        // Chỉ start scanning nếu chưa scan và có khuôn mặt hợp lệ
        if !isScanning && !hasCompletedGuess && faceFrame.width > 50 { // Ngưỡng kích thước tối thiểu
            startScanning(faceFrame: faceFrame)
        }
        
        // Xóa mọi layer không phải scanning line
        detectionLayer?.sublayers?.forEach {
            if $0 != scanningLineLayer {
                $0.removeFromSuperlayer()
            }
        }
    }
    
    private func setupDetectionLayer() {
        detectionLayer?.removeFromSuperlayer()
        detectionLayer = nil
        
        detectionLayer = CALayer()
        detectionLayer?.frame = bounds
        detectionLayer?.masksToBounds = true
        
        layer.addSublayer(detectionLayer!)
        
        setupScanningLine()
        print("Detection layer initialized with dimensions: \(detectionLayer?.frame ?? .zero)")
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
            print("yolo Scanning not started: isScanning=\(isScanning), hasCompletedGuess=\(hasCompletedGuess)")
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
        print("yolo Selected guess images - Female: \(selectedGuessImages.me ?? "none"), Male: \(selectedGuessImages.myBoy ?? "none")")
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
