import UIKit
import AVFoundation
import SDWebImage
import CoreImage
import Vision

protocol RankingViewDelegate: AnyObject {
    func didSelectRankingCell(at index: Int, image: UIImage?, imageURL: String?)
    func didStartRecording()
}

class RankingView: UIView, AVCaptureVideoDataOutputSampleBufferDelegate {
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var stackView: UIStackView!
    
    private var session: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    private var isUsingFrontCamera = true
    private let videoQueue = DispatchQueue(label: "com.ranking.videoQueue", qos: .userInteractive)
    
    private let previewImageView = UIImageView()
    private let imageOverlayView = UIImageView()
    
    private var imageURLs: [String] = []
    private var usedImageURLs: [String] = []
    private var currentImage: UIImage?
    private var currentImageURL: String?
    private var randomTimer: Timer?
    private var isRecording = false
    private var isRandomizing = false
    
    private var isActive = false
    private var currentChallenge: SurvivalChallengeEntity?
    
    weak var delegate: RankingViewDelegate?
    
    var designType: DesignType = .rankingType1 {
        didSet {
            updateLayout()
        }
    }
    
    private var faceDetectionRequest: VNDetectFaceRectanglesRequest?
    private var faceDetectionTimer: Timer?
    private var isFaceDetected = false
    private var smoothedFaceRectangle: CGRect = .zero
    private var lastFaceDetectionTime: Date?
    private let faceLostThreshold: TimeInterval = 0.3
    
    private var displayLink: CADisplayLink?
    
    var shouldKeepImagesOnReset: Bool = false
    private var cachedImageURLs: [String] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadFileXib()
        setupView()
        setupCollectionView()
        setupImageOverlay()
        updateLayout()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadFileXib()
        setupView()
        setupCollectionView()
        setupImageOverlay()
        updateLayout()
    }
    
    func loadFileXib() {
        Bundle.main.loadNibNamed("RankingView", owner: self, options: nil)
        self.addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    // MARK: - Detect Face
    private func setupFaceTracking() {
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(updateImagePosition))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func updateImagePosition() {
        guard isFaceDetected else {
            imageOverlayView.isHidden = true
            return
        }
        
        let faceCenterX = smoothedFaceRectangle.midX
        let eyebrowsY = smoothedFaceRectangle.minY + (smoothedFaceRectangle.height * 0.05)
        let imageSize = smoothedFaceRectangle.width * 0.8
        
        let targetRect = CGRect(
            x: faceCenterX - imageSize / 2,
            y: eyebrowsY - imageSize,
            width: imageSize,
            height: imageSize
        )
        
        var currentDisplayRect = imageOverlayView.frame
        if currentDisplayRect == .zero {
            currentDisplayRect = targetRect
            imageOverlayView.frame = targetRect
            imageOverlayView.isHidden = false
            return
        }
        
        let easingFactor: CGFloat = 0.5 // Tăng để di chuyển nhanh hơn
        currentDisplayRect.origin.x += (targetRect.origin.x - currentDisplayRect.origin.x) * easingFactor
        currentDisplayRect.origin.y += (targetRect.origin.y - currentDisplayRect.origin.y) * easingFactor
        currentDisplayRect.size.width += (targetRect.width - currentDisplayRect.width) * easingFactor
        currentDisplayRect.size.height += (targetRect.height - currentDisplayRect.height) * easingFactor
        
        // Giới hạn vị trí trong bounds của view
        let clampedX = max(0, min(currentDisplayRect.origin.x, bounds.width - currentDisplayRect.width))
        let clampedY = max(0, min(currentDisplayRect.origin.y, bounds.height - currentDisplayRect.height))
        currentDisplayRect.origin = CGPoint(x: clampedX, y: clampedY)
        
        imageOverlayView.frame = currentDisplayRect
        imageOverlayView.isHidden = false
    }
    
    private func setupFaceDetection() {
        faceDetectionTimer?.invalidate()
        smoothedFaceRectangle = .zero
        lastFaceDetectionTime = nil
        
        faceDetectionRequest = VNDetectFaceRectanglesRequest { [weak self] (request, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Face detection error: \(error)")
                return
            }
            
            DispatchQueue.main.async {
                guard let observations = request.results as? [VNFaceObservation],
                      let face = observations.first else {
                    if self.isFaceDetected {
                        if let lastTime = self.lastFaceDetectionTime {
                            if Date().timeIntervalSince(lastTime) > self.faceLostThreshold {
                                self.isFaceDetected = false
                                self.imageOverlayView.isHidden = true
                                self.smoothedFaceRectangle = .zero
                            }
                        } else {
                            self.lastFaceDetectionTime = Date()
                        }
                        return
                    }
                    return
                }
                
                self.isFaceDetected = true
                self.lastFaceDetectionTime = nil
                self.processDetectedFace(face)
            }
        }
        
        faceDetectionTimer = Timer.scheduledTimer(withTimeInterval: 7, repeats: true) { [weak self] _ in
            guard let self = self, self.isActive else { return }
            
            guard let image = self.previewImageView.image,
                  let cgImage = image.cgImage else { return }
            
            let orientation: CGImagePropertyOrientation = self.isUsingFrontCamera ? .leftMirrored : .right
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
            
            DispatchQueue.global(qos: .userInteractive).async {
                do {
                    if let request = self.faceDetectionRequest {
                        try handler.perform([request])
                    }
                } catch {
                    print("Error performing face detection: \(error)")
                }
            }
        }
    }
    
    private func processDetectedFace(_ face: VNFaceObservation) {
        let faceBounds = face.boundingBox
        
        let viewWidth = bounds.width
        let viewHeight = bounds.height
        
        let faceX = faceBounds.origin.x * viewWidth
        let faceY = (1 - faceBounds.origin.y - faceBounds.height) * viewHeight
        let faceWidth = faceBounds.width * viewWidth
        let faceHeight = faceBounds.height * viewHeight
        
        let currentFaceRect = CGRect(x: faceX, y: faceY, width: faceWidth, height: faceHeight)
        
        // Làm mượt tọa độ khuôn mặt
        let smoothFactor: CGFloat = 0.3 // Tăng để làm mượt mạnh hơn
        if smoothedFaceRectangle == .zero {
            smoothedFaceRectangle = currentFaceRect
        } else {
            smoothedFaceRectangle = CGRect(
                x: smoothedFaceRectangle.origin.x * (1 - smoothFactor) + currentFaceRect.origin.x * smoothFactor,
                y: smoothedFaceRectangle.origin.y * (1 - smoothFactor) + currentFaceRect.origin.y * smoothFactor,
                width: smoothedFaceRectangle.width * (1 - smoothFactor) + currentFaceRect.width * smoothFactor,
                height: smoothedFaceRectangle.height * (1 - smoothFactor) + currentFaceRect.height * smoothFactor
            )
        }
    }
    
    private func getCurrentPixelBuffer() -> CVPixelBuffer? {
        guard let image = previewImageView.image, let cgImage = image.cgImage else {
            return nil
        }
        
        var pixelBuffer: CVPixelBuffer?
        let width = cgImage.width
        let height = cgImage.height
        
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
             kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        
        CVPixelBufferCreate(kCFAllocatorDefault,
                            width, height,
                            kCVPixelFormatType_32ARGB,
                            attrs,
                            &pixelBuffer)
        
        if let pixelBuffer = pixelBuffer {
            let context = CIContext()
            let ciImage = CIImage(cgImage: cgImage)
            context.render(ciImage, to: pixelBuffer)
            return pixelBuffer
        }
        
        return nil
    }
    
    // MARK: - Setup View
    private func setupView() {
        previewImageView.contentMode = .scaleAspectFill
        previewImageView.clipsToBounds = true
        
        insertSubview(previewImageView, at: 0)
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            previewImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            previewImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            previewImageView.topAnchor.constraint(equalTo: topAnchor),
            previewImageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        insertSubview(imageOverlayView, aboveSubview: previewImageView)
        
        setupFaceDetection()
        
        if let contentView = contentView {
            bringSubviewToFront(contentView)
        }
    }
    
    private func setupImageOverlay() {
        imageOverlayView.contentMode = .scaleAspectFit
        imageOverlayView.clipsToBounds = true
        imageOverlayView.isHidden = true
        imageOverlayView.translatesAutoresizingMaskIntoConstraints = true
        setupFaceTracking()
    }
    
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
    
    deinit {
        faceDetectionTimer?.invalidate()
        displayLink?.invalidate()
        print("⚙️ deinit \(Self.self)")
    }
    
    func activate() {
        isActive = true
        startContinuousRandomization()
        setupFaceDetection()
    }
    
    // MARK: - Record
    func startRecording() {
        isRecording = true
        stopRandomization()
        startLimitedRandomization()
    }
    
    func stopRecording() {
        isRecording = false
        stopRandomization()
        
        if !shouldKeepImagesOnReset {
            startContinuousRandomization()
        }
    }
    
    func setPreviewSession(_ session: AVCaptureSession?, _ isFrontCamera: Bool) {
        guard let session = session else { return }
        self.session = session
        self.isUsingFrontCamera = isFrontCamera
        
        if let existingOutput = videoOutput {
            session.removeOutput(existingOutput)
        }
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: videoQueue)
        
        if session.canAddOutput(output) {
            session.addOutput(output)
            videoOutput = output
            print("Successfully set up video output")
        } else {
            print("Failed to add video output to session")
        }
    }
    
    func prepareForCameraSwap() {
        let snapshot = previewImageView.image
        DispatchQueue.main.async {
            self.previewImageView.image = snapshot
        }
    }
    
    func setChallenge(_ challenge: SurvivalChallengeEntity?) {
        guard let challenge = challenge else {
            resetState()
            return
        }
        
        currentChallenge = challenge
        imageURLs = Array(challenge.imgOptionUrl)
        
        // Only reset usedImageURLs if not preserving state
        if !shouldKeepImagesOnReset {
            usedImageURLs = []
            
            print("yolo Random image URLs for challenge '\(challenge.name)':")
            imageURLs.forEach { url in
                print("yolo - \(url)")
            }
            
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
        } else {
            // If should keep images, preserve the existing usedImageURLs
            print("yolo Preserving used images for challenge '\(challenge.name)'")
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.collectionView?.reloadData()
            if ((self?.isRecording) != nil) {
                self?.startContinuousRandomization()
            }
        }
    }
    
    func resetState() {
        if !shouldKeepImagesOnReset {
            imageURLs = []
            usedImageURLs = []
            currentImage = nil
            currentImageURL = nil
            currentChallenge = nil
            stopRandomization()
            
            DispatchQueue.main.async { [weak self] in
                self?.imageOverlayView.isHidden = true
                self?.collectionView?.reloadData()
                self?.collectionView?.isUserInteractionEnabled = false
                self?.updateLayout()
            }
            print("yolo RankingView state reset (full)")
        } else {
            // Only stop randomization but keep state
            stopRandomization()
            
            DispatchQueue.main.async { [weak self] in
                self?.imageOverlayView.isHidden = true
                // Make sure the collection view is still user interactive
                self?.collectionView?.isUserInteractionEnabled = true
            }
            
            print("yolo RankingView state maintained - keeping \(usedImageURLs.count) images")
        }
    }
    
    func restoreCachedImages() {
        if shouldKeepImagesOnReset && !usedImageURLs.isEmpty {
            print("yolo Restoring cached RankingView images - total images: \(usedImageURLs.count)")
            
            // Enable user interaction with the collection view
            collectionView?.isUserInteractionEnabled = true
            
            // Reload the collection view to show the cached images
            DispatchQueue.main.async { [weak self] in
                self?.collectionView?.reloadData()
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isActive, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let orientedImage = isUsingFrontCamera ? ciImage.oriented(.leftMirrored) : ciImage.oriented(.right)
        
        if let cgImage = ciContext.createCGImage(orientedImage, from: orientedImage.extent) {
            let uiImage = UIImage(cgImage: cgImage)
            DispatchQueue.main.async { [weak self] in
                self?.previewImageView.image = uiImage
            }
            
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: isUsingFrontCamera ? .leftMirrored : .right)
            
            do {
                try imageRequestHandler.perform([faceDetectionRequest].compactMap { $0 })
            } catch {
                print("Error performing face detection: \(error)")
            }
        }
    }
    
    private func startContinuousRandomization() {
        stopRandomization()
        
        isRandomizing = true
        collectionView?.isUserInteractionEnabled = false
        
        randomTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.randomizeNextImage()
        }
    }
    
    private func startLimitedRandomization() {
        stopRandomization()
        
        isRandomizing = true
        collectionView?.isUserInteractionEnabled = false
        
        randomTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            self?.randomizeNextImage()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            self.stopRandomization()
            self.collectionView?.isUserInteractionEnabled = true
        }
    }
    
    private func stopRandomization() {
        randomTimer?.invalidate()
        randomTimer = nil
        isRandomizing = false
    }
    
    private func randomizeNextImage() {
        guard usedImageURLs.count < imageURLs.count else {
            print("All images have been used. Stopping randomization.")
            currentImage = nil
            currentImageURL = nil
            stopRandomization()
            imageOverlayView.isHidden = true
            return
        }
        
        let availableURLs = imageURLs.filter { !usedImageURLs.contains($0) }
        
        guard !availableURLs.isEmpty else {
            print("No available URLs after filtering")
            return
        }
        
        if !isFaceDetected {
            imageOverlayView.isHidden = true
            selectRandomImage(from: availableURLs)
        } else {
            selectRandomImage(from: availableURLs)
            imageOverlayView.isHidden = false
        }
    }
    
    private func selectRandomImage(from availableURLs: [String]) {
        let randomIndex = Int.random(in: 0..<availableURLs.count)
        let urlString = availableURLs[randomIndex]
        
        currentImageURL = urlString
        
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
                    
                    self.imageOverlayView.image = self.currentImage
                    self.imageOverlayView.isHidden = !self.isFaceDetected
                }
            }
        } else {
            print("Invalid URL: \(urlString)")
            currentImage = UIImage(systemName: "photo")
            currentImageURL = nil
        }
    }
}

// MARK: - Layout
extension RankingView {
    private func updateLayout() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        switch designType {
        case .rankingType1:
            stackView?.isHidden = false
            setupStackViewForType1()
        case .rankingType2:
            stackView?.isHidden = true
            layoutIfNeeded()
        case .rankingType3:
            stackView?.isHidden = false
            updateStackViewImages()
        default:
            break
        }
        collectionView?.reloadData()
    }
    
    private func setupStackViewForType1() {
        guard let stackView = stackView else { return }
        
        for index in 0..<10 {
            let imageView = UIImageView()
            
            if index < 5 {
                imageView.image = .likeIc
            } else {
                imageView.image = .dislikeIc
            }
            
            imageView.contentMode = .scaleAspectFit
            stackView.addArrangedSubview(imageView)
        }
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
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RankingCell", for: indexPath) as? RankingCell else {
            return UICollectionViewCell()
        }
        let rankingCellStyle = designToRankingMap[designType] ?? .case1
        cell.configureCell(style: rankingCellStyle, index: indexPath.row)
        
        if indexPath.row < usedImageURLs.count {
            if let url = URL(string: usedImageURLs[indexPath.row]) {
                cell.bgImage.sd_setImage(with: url, placeholderImage: UIImage(systemName: "photo"))
                cell.bgImage.isHidden = false
            }
        } else {
            cell.bgImage.image = UIImage(named: "squidgame")
            cell.bgImage.isHidden = true
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Select row at: \(indexPath.row)")
        guard let cell = collectionView.cellForItem(at: indexPath) as? RankingCell,
              let image = currentImage,
              let imageURL = currentImageURL else {
            print("No valid image or cell at index \(indexPath.row)")
            return
        }
        
        cell.bgImage.image = image
        cell.bgImage.isHidden = false
        cell.animateSelection()
        
        usedImageURLs.append(imageURL)
        print("Added to used URLs: \(imageURL). Total used: \(usedImageURLs.count)/\(imageURLs.count)")
        
        delegate?.didSelectRankingCell(at: indexPath.row, image: image, imageURL: imageURL)
        
        imageOverlayView.isHidden = true
        
        if isRecording {
            stopRandomization()
            startLimitedRandomization()
        } else {
            startContinuousRandomization()
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
