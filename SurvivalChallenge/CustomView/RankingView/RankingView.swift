import UIKit
import AVFoundation
import SDWebImage
import CoreImage

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
        
        if let contentView = contentView {
            bringSubviewToFront(contentView)
        }
        
        if let collectionView = collectionView {
            bringSubviewToFront(collectionView)
        }
        
        if let stackView = stackView {
            bringSubviewToFront(stackView)
        }
    }
    
    // Thiết lập imageOverlayView để hiển thị ảnh ở giữa màn hình
    private func setupImageOverlay() {
        imageOverlayView.contentMode = .scaleAspectFit
        imageOverlayView.clipsToBounds = true
        imageOverlayView.isHidden = true
        
        addSubview(imageOverlayView)
        imageOverlayView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageOverlayView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageOverlayView.topAnchor.constraint(equalTo: topAnchor, constant: 50), // Cách top 50
            imageOverlayView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.6),
            imageOverlayView.heightAnchor.constraint(equalTo: imageOverlayView.widthAnchor, multiplier: 1.0)
        ])
        
        bringSubviewToFront(imageOverlayView)
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
//        deactivate()
        print("⚙️ deinit \(Self.self)")
    }
    
    func activate() {
        isActive = true
        startContinuousRandomization()
    }
    
//    func deactivate() {
//        isActive = false
//        if let videoOutput = videoOutput {
//            videoOutput.setSampleBufferDelegate(nil, queue: nil)
//        }
//        stopRandomization()
//        DispatchQueue.main.async {
//            self.previewImageView.image = nil
//            self.imageOverlayView.isHidden = true
//        }
//    }
    
    func startRecording() {
        isRecording = true
        stopRandomization()
        startLimitedRandomization()
    }
    
    // Phương thức để dừng ghi hình
    func stopRecording() {
        isRecording = false
        stopRandomization() // Dừng random hiện tại
        startContinuousRandomization() // Bắt đầu lại random liên tục
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
        
        DispatchQueue.main.async { [weak self] in
            self?.collectionView?.reloadData()
            if ((self?.isRecording) != nil) {
                self?.startContinuousRandomization()
            }
        }
    }
    
    func resetState() {
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
        print("yolo RankingView state reset")
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
        }
    }
    
    // MARK: - Randomization Methods
    
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
            print("yolo All images have been used. Stopping randomization.")
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
        
        selectRandomImage(from: availableURLs)
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
                    self.imageOverlayView.isHidden = false
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
