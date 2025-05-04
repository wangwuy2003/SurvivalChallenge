import UIKit
import Stevia
import AVFoundation
import SDWebImage

class GuessView: UIView {
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var meView: UIView!
    @IBOutlet weak var myBoyView: UIView!
    @IBOutlet weak var meImage: UIImageView!
    @IBOutlet weak var myBoyImage: UIImageView!
    @IBOutlet weak var contentImageView: UIView!
    
    var designType: DesignType = .guessType
    
    private var session: AVCaptureSession?
    private var isUsingFrontCamera = true
    private var isScanning = false
    private var hasCompletedGuess = false
    private var guessImageURLs: (me: [String], myBoy: [String]) = ([], [])
    private var selectedGuessImages: (me: String?, myBoy: String?) = (nil, nil)
    private var isActive = false
    
    private let previewImageView = UIImageView()
    private let scanlineImageView = UIImageView()
    
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
        // Check outlets to avoid crash
        if let meView = meView, let myBoyView = myBoyView {
            meView.borderColor = .hexED0384
            meView.borderWidth = 4
            myBoyView.borderColor = .hexED0384
            myBoyView.borderWidth = 4
        }
        
        // Setup preview image view (optional, can be used for static background if needed)
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
        
        // Setup scanline image view
        scanlineImageView.image = .scanLine
        scanlineImageView.contentMode = .scaleToFill
        scanlineImageView.clipsToBounds = true
        scanlineImageView.isHidden = true
        insertSubview(scanlineImageView, aboveSubview: previewImageView)
        scanlineImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scanlineImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scanlineImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scanlineImageView.heightAnchor.constraint(equalToConstant: 4),
            scanlineImageView.topAnchor.constraint(equalTo: topAnchor) // Initial position
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
        isScanning = false
        hasCompletedGuess = false
        selectedGuessImages = (nil, nil)
        resetImages()
        stopScanning()
        print("yolo GuessView state reset")
    }
    
    func startRecording() {
        guard !isScanning, !hasCompletedGuess, isActive else {
            print("yolo Cannot start scanning: isScanning=\(isScanning), hasCompletedGuess=\(hasCompletedGuess)")
            return
        }
        startScanning()
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
    
    // MARK: - Scanline Animation
    private func startScanning() {
        guard !isScanning, !hasCompletedGuess, isActive else {
            print("yolo Scanning not started: isScanning=\(isScanning), hasCompletedGuess=\(hasCompletedGuess)")
            return
        }
        isScanning = true
        scanlineImageView.isHidden = false
        
        let viewHeight = bounds.height
        let startY: CGFloat = 0
        let endY: CGFloat = viewHeight
        
        // Reset scanline to top
        scanlineImageView.transform = .identity
        
        // Animate scanline from top to bottom and back
        UIView.animateKeyframes(withDuration: 3.0, delay: 0, options: [.calculationModeLinear], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                self.scanlineImageView.transform = CGAffineTransform(translationX: 0, y: endY)
            }
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                self.scanlineImageView.transform = CGAffineTransform(translationX: 0, y: 0)
            }
        }, completion: { [weak self] finished in
            guard let self = self, finished else { return }
            self.stopScanning()
            self.selectGuessImages()
        })
        
        print("yolo Started scanning animation")
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
