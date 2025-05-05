import UIKit
import Stevia
import AVFoundation
import SDWebImage
import AlamofireImage
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
    private var isUsingFrontCamera = true
    private var videoOutput: AVCaptureVideoDataOutput?
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    private var isScanning = false
    private var hasCompletedGuess = false
    private var guessImageURLs: (me: [String], myBoy: [String]) = ([], [])
    private var selectedGuessImages: (me: String?, myBoy: String?) = (nil, nil)
    private var isActive = false
    
    private let videoQueue = DispatchQueue(label: "com.guess.videoQueue", qos: .userInteractive)
    
    private let previewImageView = UIImageView()
    private let scanlineImageView = UIImageView()
    
    var shouldKeepImagesOnReset: Bool = false
    var cachedMeImageUrl: String?
    var cachedMyBoyImageUrl: String?
    
    // MARK: - Initialization
    override func awakeFromNib() {
        super.awakeFromNib()
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
//        deactivate()
        print("⚙️ deinit \(Self.self)")
    }
    
    // MARK: - Setup
    func loadFileXib() {
        Bundle.main.loadNibNamed("GuessView", owner: self, options: nil)
        self.addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func setupView() {
        meView.borderColor = .hexED0384
        meView.borderWidth = 4
        myBoyView.borderColor = .hexED0384
        myBoyView.borderWidth = 4
        
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
        
        scanlineImageView.image = .scanLine
        scanlineImageView.contentMode = .scaleToFill
        scanlineImageView.clipsToBounds = true
        scanlineImageView.isHidden = true
        insertSubview(scanlineImageView, aboveSubview: previewImageView)
        scanlineImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scanlineImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scanlineImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scanlineImageView.heightAnchor.constraint(equalToConstant: 60),
            scanlineImageView.topAnchor.constraint(equalTo: topAnchor)
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
        stopScanning()
        session = nil
        DispatchQueue.main.async {
            self.previewImageView.image = nil
            self.scanlineImageView.isHidden = true
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
        
        guessImageURLs.me = challenge.imgOptionUrl.filter { $0.contains("/Nu/") }
        guessImageURLs.myBoy = challenge.imgOptionUrl.filter { $0.contains("/Nam/") }
        print("yolo Guess filter - Female images: \(guessImageURLs.me.count), Male images: \(guessImageURLs.myBoy.count) for challenge: \(challenge.name)")
        
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
//        isScanning = false
//        hasCompletedGuess = false
//        selectedGuessImages = (nil, nil)
//        resetImages()
//        stopScanning()
//        print("yolo GuessView state reset")
        
        isScanning = false
            
        if shouldKeepImagesOnReset && hasCompletedGuess {
            print("yolo GuessView keeping images during reset")
        } else {
            // Standard reset behavior
            hasCompletedGuess = false
            selectedGuessImages = (nil, nil)
            resetImages()
            cachedMeImageUrl = nil
            cachedMyBoyImageUrl = nil
        }
        
        stopScanning()
        print("yolo GuessView state reset with keepImages=\(shouldKeepImagesOnReset)")
    }
    
    func startRecording() {
        guard !isScanning, !hasCompletedGuess, isActive else {
            print("yolo Cannot start scanning: isScanning=\(isScanning), hasCompletedGuess=\(hasCompletedGuess)")
            return
        }
        startScanning()
    }
    
    // MARK: - Camera Output Processing (Added from RankingView)
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
    
    // MARK: - UI Methods
    func resetImages() {
        if let meImage = meImage, let myBoyImage = myBoyImage {
            meImage.image = .squidgame
            myBoyImage.image = .squidgame
            meImage.alpha = 1
            myBoyImage.alpha = 1
            print("yolo GuessView images reset")
        }
    }
    
    func setImages(meUrl: String?, myBoyUrl: String?) {
        
        cachedMeImageUrl = meUrl
        cachedMyBoyImageUrl = myBoyUrl
        
        guard let meImage = meImage, let myBoyImage = myBoyImage else {
            print("Error: Image views are nil in setImages")
            return
        }
        
        meImage.image = .squidgame
        myBoyImage.image = .squidgame
        meImage.alpha = 1
        myBoyImage.alpha = 1
        
        if let meUrl = meUrl, let url = URL(string: meUrl) {
            let placeholder = UIImage.squidgame
            
            meImage.af.setImage(
                withURL: url,
                placeholderImage: placeholder,
                filter: nil,
                progress: nil,
                progressQueue: DispatchQueue.main,
                imageTransition: .crossDissolve(0.5),
                runImageTransitionIfCached: false,
                completion: { [weak self] response in
                    guard let self else { return }
                    switch response.result {
                    case .success(let image):
                        print("yolo Loaded meImage: \(meUrl)")
                    case .failure(let error):
                        print("yolo Failed to load meImage: \(error.localizedDescription)")
                    }
                }
            )
        }
        
        if let myBoyUrl = myBoyUrl, let url = URL(string: myBoyUrl) {
            let placeholder = UIImage.squidgame
            
            ImageDownloader.default.download(URLRequest(url: url), completion: { [weak self] response in
                guard let self else { return }
                guard let _ = response.value else {
                    print("yolo Failed to load myBoyImage")
                    return
                }
                
                print("yolo Loaded myBoyImage: \(myBoyUrl)")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    myBoyImage.af.setImage(
                        withURL: url,
                        placeholderImage: placeholder,
                        filter: nil,
                        progress: nil,
                        progressQueue: DispatchQueue.main,
                        imageTransition: .crossDissolve(0.5),
                        runImageTransitionIfCached: true,
                        completion: nil
                    )
                }
            })
        }
    }
    
    func restoreCachedImages() {
        if hasCompletedGuess && cachedMeImageUrl != nil && cachedMyBoyImageUrl != nil {
            print("yolo Restoring cached GuessView images")
            setImages(meUrl: cachedMeImageUrl, myBoyUrl: cachedMyBoyImageUrl)
        }
    }
    
    // MARK: - Scanline Animation
    private func startScanning() {
        guard !isScanning, !hasCompletedGuess, isActive else {
            print("yolo Scanning not started: isScanning=\(isScanning), hasCompletedGuess=\(hasCompletedGuess)")
            return
        }
        isScanning = true
        scanlineImageView.isHidden = false
        
        let viewHeight = bounds.height
        // Calculate middle 2/3 of the screen
        let startY = viewHeight / 6  // 1/6 from the top
        let endY = viewHeight * 5 / 6  // 5/6 from the top (or 1/6 from the bottom)
        let scanDistance = endY - startY
        
        // Position scanline at the starting position (1/6 from top)
        scanlineImageView.transform = CGAffineTransform(translationX: 0, y: startY)
        
        // Animate scanline only through the middle 2/3 of the screen
        UIView.animateKeyframes(withDuration: 3.0, delay: 0, options: [.calculationModeLinear], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                // Move down to 5/6 position
                self.scanlineImageView.transform = CGAffineTransform(translationX: 0, y: endY)
            }
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                // Move back up to 1/6 position
                self.scanlineImageView.transform = CGAffineTransform(translationX: 0, y: startY)
            }
        }, completion: { [weak self] finished in
            guard let self = self, finished else { return }
            self.stopScanning()
            self.selectGuessImages()
        })
        
        print("yolo Started scanning animation in middle 2/3 of screen")
    }
    
    private func stopScanning() {
        isScanning = false
        scanlineImageView.isHidden = true
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
