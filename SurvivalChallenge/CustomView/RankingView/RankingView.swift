//
//  RankingView.swift
//  SurvivalChallenge
//
//  Created by Apple on 19/4/25.
//

import UIKit
import AVFoundation
import MLKitFaceDetection
import MLKit
import SDWebImage

protocol RankingViewDelegate: AnyObject {
    func didSelectRankingCell(at index: Int, image: UIImage?, imageURL: String?)
}

class RankingView: UIView, AVCaptureVideoDataOutputSampleBufferDelegate {
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var stackView: UIStackView!
    
    // MARK: - Private Properties
    private var session: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var ciContext: CIContext?
    private var isUsingFrontCamera = true
    private let videoQueue = DispatchQueue(label: "com.ranking.videoQueue", qos: .userInteractive)
    
    private var imageURLs: [String] = []
    private var usedImageURLs: [String] = []
    private var currentImage: UIImage?
    private var currentImageURL: String?
    private var randomTimer: Timer?
    private var stopRandomTimer: Timer?
    
    private var previousLeftEyePoint: CGPoint?
    private var previousRightEyePoint: CGPoint?
    private var smoothingFactor: CGFloat = 0.7
    private var minimumChangeThreshold: CGFloat = 3.0
    private var isProcessing = false
    private var isActive = false
    
    private var currentChallenge: SurvivalChallengeEntity?
    
    // MARK: - Public Properties
    weak var delegate: RankingViewDelegate?
    
    var designType: DesignType = .rankingType1 {
        didSet {
            updateLayout()
        }
    }
    
    // MARK: - Initialization
    override func awakeFromNib() {
        super.awakeFromNib()
        print("yolo RankingView awakeFromNib called")
        setupCollectionView()
        updateLayout()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        print("yolo RankingView init(frame:) called")
        
        // Load view from nib với owner là nil (không phải RankingView)
        if let contentView = Bundle.main.loadNibNamed("RankingView", owner: nil, options: nil)?.first as? UIView {
            contentView.frame = bounds
            contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(contentView)
        }
        
        setupCollectionView()
        updateLayout()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        print("yolo RankingView init(coder:) called")
    }
    
    deinit {
        deactivate()
        print("⚙️ deinit \(Self.self)")
    }
    
    // MARK: - Setup Methods
    func setupCollectionView() {
        guard let collectionView = collectionView else {
            print("Error: collectionView is nil in setupCollectionView")
            return
        }
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "RankingCell", bundle: nil),
                               forCellWithReuseIdentifier: "RankingCell")
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        print("yolo setupCollectionView completed")
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
        stopRandom()
        ciContext = nil
        previousLeftEyePoint = nil
        previousRightEyePoint = nil
        isProcessing = false
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
        currentChallenge = challenge
        imageURLs = Array(challenge.imgOptionUrl)
        usedImageURLs = []
        
        print("yolo Random image URLs for challenge '\(challenge.name)':")
        imageURLs.forEach { url in
            print("yolo - \(url)")
        }
        
        // Preload images
        for url in imageURLs {
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
        
        DispatchQueue.main.async { [weak self] in
            self?.collectionView?.reloadData()
            self?.startRandomizationCycle()
        }
    }
    
    func resetState() {
        imageURLs = []
        usedImageURLs = []
        currentImage = nil
        currentImageURL = nil
        currentChallenge = nil
        stopRandom()
        previousLeftEyePoint = nil
        previousRightEyePoint = nil
        isProcessing = false
        
        DispatchQueue.main.async { [weak self] in
            self?.collectionView?.reloadData()
            self?.collectionView?.isUserInteractionEnabled = false
            self?.updateLayout() // Ensure stackView is updated
        }
        print("yolo RankingView state reset")
    }
    
    // MARK: - Face Detection
    func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, imageSize: CGSize) {
        guard isActive, !isProcessing else { return }
        isProcessing = true
        
        // Lazy khởi tạo CIContext chỉ khi cần
        if ciContext == nil {
            ciContext = CIContext(options: [.useSoftwareRenderer: false])
        }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            isProcessing = false
            print("Failed to obtain pixel buffer")
            return
        }
        
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        ciImage = isUsingFrontCamera ? ciImage.oriented(.leftMirrored) : ciImage.oriented(.right)
        
        let visionImage = VisionImage(buffer: sampleBuffer)
        visionImage.orientation = imageOrientation()
        
        detectFaces(in: visionImage, ciImage: ciImage, imageSize: imageSize, sampleBuffer: sampleBuffer)
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
    
    private func detectFaces(in visionImage: VisionImage, ciImage: CIImage, imageSize: CGSize, sampleBuffer: CMSampleBuffer) {
        let options = FaceDetectorOptions()
        options.performanceMode = .accurate
        options.landmarkMode = .all
        options.classificationMode = .all
        
        let faceDetector = FaceDetector.faceDetector(options: options)
        
        faceDetector.process(visionImage) { [weak self] faces, error in
            guard let self = self, self.isActive else {
                self?.isProcessing = false
                return
            }
            
            if let error = error {
                print("Lỗi khi nhận diện khuôn mặt: \(error.localizedDescription)")
                self.isProcessing = false
                return
            }
            
            guard let faces = faces, !faces.isEmpty else {
                print("Không tìm thấy khuôn mặt")
                self.isProcessing = false
                return
            }
            
            print("Found \(faces.count) face(s)")
            for face in faces {
                self.drawFaceFrame(face, ciImage: ciImage, imageSize: imageSize, sampleBuffer: sampleBuffer)
            }
            self.isProcessing = false
        }
    }
    
    private func drawFaceFrame(_ face: Face, ciImage: CIImage, imageSize: CGSize, sampleBuffer: CMSampleBuffer) {
        let leftEye = face.landmark(ofType: .leftEye)?.position
        let rightEye = face.landmark(ofType: .rightEye)?.position
        
        guard let leftEyePos = leftEye, let rightEyePos = rightEye else {
            print("No eye landmarks found")
            isProcessing = false
            return
        }
        
        // Convert to view coordinates
        let leftEyePointConverted = convertToImageCoordinates(CGPoint(x: leftEyePos.x, y: leftEyePos.y), imageSize: imageSize)
        let rightEyePointConverted = convertToImageCoordinates(CGPoint(x: rightEyePos.x, y: rightEyePos.y), imageSize: imageSize)
        
        var smoothedLeftEyePoint = leftEyePointConverted
        var smoothedRightEyePoint = rightEyePointConverted
        
        if let previousLeft = previousLeftEyePoint, let previousRight = previousRightEyePoint {
            let leftDistance = CGPoint.distance(from: previousLeft, to: leftEyePointConverted)
            let rightDistance = CGPoint.distance(from: previousRight, to: rightEyePointConverted)
            
            if leftDistance < minimumChangeThreshold && rightDistance < minimumChangeThreshold {
                smoothedLeftEyePoint = previousLeft
                smoothedRightEyePoint = previousRight
            } else {
                smoothedLeftEyePoint = CGPoint(
                    x: previousLeft.x * smoothingFactor + leftEyePointConverted.x * (1 - smoothingFactor),
                    y: previousLeft.y * smoothingFactor + leftEyePointConverted.y * (1 - smoothingFactor)
                )
                
                smoothedRightEyePoint = CGPoint(
                    x: previousRight.x * smoothingFactor + rightEyePointConverted.x * (1 - smoothingFactor),
                    y: previousRight.y * smoothingFactor + rightEyePointConverted.y * (1 - smoothingFactor)
                )
            }
        }
        
        previousLeftEyePoint = smoothedLeftEyePoint
        previousRightEyePoint = smoothedRightEyePoint
        
        let eyebrowOffsetY = 25.0
        let leftEyebrowPoint = CGPoint(x: smoothedLeftEyePoint.x, y: smoothedLeftEyePoint.y - eyebrowOffsetY)
        let rightEyebrowPoint = CGPoint(x: smoothedRightEyePoint.x, y: smoothedRightEyePoint.y - eyebrowOffsetY)
        
        let eyebrowDistance = CGPoint.distance(from: leftEyebrowPoint, to: rightEyebrowPoint)
        let imageWidth = eyebrowDistance * 2.0
        
        guard let currentImage = currentImage,
              let currentImageURL = currentImageURL,
              !usedImageURLs.contains(currentImageURL) else {
            print("No valid image or image already used: \(currentImageURL ?? "none")")
            isProcessing = false
            return
        }
        
        let aspectRatio = currentImage.size.height / currentImage.size.width
        let imageHeight = imageWidth * aspectRatio
        
        let centerX = (leftEyebrowPoint.x + rightEyebrowPoint.x) / 2
        let eyebrowY = min(leftEyebrowPoint.y, rightEyebrowPoint.y)
        let offsetAboveEyebrow = 30.0
        
        let imageFrame = CGRect(
            x: centerX - imageWidth / 2,
            y: eyebrowY - imageHeight - offsetAboveEyebrow,
            width: imageWidth,
            height: imageHeight
        )
        
        // Render image onto buffer
        renderImage(currentImage, in: imageFrame, ciImage: ciImage, sampleBuffer: sampleBuffer)
        
        print("Rendered image: \(currentImageURL)")
    }
    
    private func convertToImageCoordinates(_ point: CGPoint, imageSize: CGSize) -> CGPoint {
        // Normalize to [0,1] based on image size
        let normalizedX = point.x / imageSize.width
        let normalizedY = point.y / imageSize.height
        // Map to CIImage coordinates
        return CGPoint(x: normalizedX * imageSize.width, y: (1 - normalizedY) * imageSize.height)
    }
    
    private func renderImage(_ image: UIImage, in frame: CGRect, ciImage: CIImage, sampleBuffer: CMSampleBuffer) {
        guard let ciContext = ciContext,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let cgImage = image.cgImage else {
            isProcessing = false
            return
        }
        
        var overlayImage = CIImage(cgImage: cgImage)
        overlayImage = overlayImage.transformed(by: CGAffineTransform(scaleX: frame.width / overlayImage.extent.width, y: frame.height / overlayImage.extent.height))
        overlayImage = overlayImage.transformed(by: CGAffineTransform(translationX: frame.origin.x, y: ciImage.extent.height - frame.origin.y - frame.height))
        
        let compositedImage = overlayImage.composited(over: ciImage)
        
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        ciContext.render(compositedImage, to: pixelBuffer)
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isActive, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let imageSize = CGSize(
            width: CVPixelBufferGetWidth(pixelBuffer),
            height: CVPixelBufferGetHeight(pixelBuffer)
        )
        
        processSampleBuffer(sampleBuffer, imageSize: imageSize)
    }
    
    // MARK: - Random Image Logic
    private func startRandomizationCycle() {
        stopRandom()
        
        collectionView?.isUserInteractionEnabled = false
        
        randomTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            self?.randomImage()
        }
        
        stopRandomTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.stopRandom()
            self?.collectionView?.isUserInteractionEnabled = true
            print("yolo Randomization stopped at image: \(self?.currentImageURL ?? "none")")
        }
    }
    
    private func randomImage() {
        guard usedImageURLs.count < imageURLs.count else {
            print("yolo All images have been used. Stopping randomization.")
            currentImage = nil
            currentImageURL = nil
            stopRandom()
            collectionView?.isUserInteractionEnabled = false
            return
        }
        
        let availableURLs = imageURLs.filter { !usedImageURLs.contains($0) }
        
        guard !availableURLs.isEmpty else {
            print("No available URLs after filtering")
            return
        }
        
        selectRandomImage(from: availableURLs)
    }
    
    private func selectRandomImage(from availableURLs: [String]) {
        let randomIndex = Int.random(in: 0..<availableURLs.count)
        let urlString = availableURLs[randomIndex]
        
        currentImageURL = urlString
        print("yolo Selected random image URL: \(urlString)")
        if let url = URL(string: urlString) {
            SDWebImageDownloader.shared.downloadImage(with: url, options: [.highPriority, .scaleDownLargeImages], progress: nil) { [weak self] (image, _, error, _) in
                DispatchQueue.main.async {
                    guard let self = self, self.currentImageURL == urlString else {
                        print("Skipping outdated image for \(urlString)")
                        return
                    }
                    if let error = error {
                        print("Failed to load image \(urlString): \(error.localizedDescription)")
                        self.currentImage = UIImage(systemName: "photo")
                    } else {
                        self.currentImage = image ?? UIImage(systemName: "photo")
                    }
                    print("Random image loaded: \(urlString)")
                }
            }
        } else {
            print("Invalid URL: \(urlString)")
            currentImage = UIImage(systemName: "photo")
            currentImageURL = nil
        }
    }
    
    private func stopRandom() {
        randomTimer?.invalidate()
        stopRandomTimer?.invalidate()
        randomTimer = nil
        stopRandomTimer = nil
    }
}

// MARK: - Layout
extension RankingView {
    private func updateLayout() {
        switch designType {
        case .rankingType1:
            stackView?.isHidden = false
            stackView?.arrangedSubviews.forEach { $0.isHidden = false }
        case .rankingType2:
            stackView?.isHidden = true
        case .rankingType3:
            stackView?.isHidden = false
            updateStackViewImages()
        default:
            break
        }
        collectionView?.reloadData()
    }
    
    private func updateStackViewImages() {
        guard let stackView = stackView else {
            print("Error: stackView is nil in updateStackViewImages")
            return
        }
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let imageMappings: [(range: Range<Int>, image: UIImage)] = [
            (0..<3, .imageRing),
            (3..<6, .imageKiss),
            (6..<10, .imageDeath)
        ]
        
        for mapping in imageMappings {
            for _ in mapping.range {
                let imageView = UIImageView()
                imageView.image = mapping.image
                imageView.contentMode = .scaleAspectFit
                stackView.addArrangedSubview(imageView)
            }
        }
    }
}

// MARK: - Collection View
extension RankingView: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10 // Always 10 cells as per requirement
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RankingCell", for: indexPath) as? RankingCell else {
            return UICollectionViewCell()
        }
        let rankingCellStyle = designToRankingMap[designType] ?? .case1
        cell.configureCell(style: rankingCellStyle, index: indexPath.row)
        
        // Update cell with image if it has been selected
        if indexPath.row < usedImageURLs.count {
            if let url = URL(string: usedImageURLs[indexPath.row]) {
                cell.bgImage.sd_setImage(with: url, placeholderImage: UIImage(systemName: "photo"))
                cell.bgImage.isHidden = false
            }
        } else {
            cell.bgImage.image = UIImage(named: "squidgame") // Placeholder
            cell.bgImage.isHidden = true
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? RankingCell,
              let image = currentImage,
              let imageURL = currentImageURL else {
            print("No valid image or cell at index \(indexPath.row)")
            return
        }
        
        // Update cell with selected image
        cell.bgImage.image = image
        cell.bgImage.isHidden = false
        cell.animateSelection()
        
        // Add to used URLs
        usedImageURLs.append(imageURL)
        print("Added to used URLs: \(imageURL). Total used: \(usedImageURLs.count)/\(imageURLs.count)")
        
        // Notify delegate
        delegate?.didSelectRankingCell(at: indexPath.row, image: image, imageURL: imageURL)
        
        // Stop randomization and restart if needed
        stopRandom()
        collectionView.isUserInteractionEnabled = false
        
        if usedImageURLs.count >= imageURLs.count {
            print("All images have been selected. No more randomization.")
            currentImage = nil
            currentImageURL = nil
        } else {
            startRandomizationCycle()
        }
    }
}

extension RankingView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 44, height: 44)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}
