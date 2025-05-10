import UIKit
import AVFoundation

class ColoringView: UIView, AVCaptureVideoDataOutputSampleBufferDelegate {
    @IBOutlet weak var paintView: UIView!
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var targetImageView: UIImageView!
    @IBOutlet weak var paintImageView: UIImageView!
    
    // button filter type1
    @IBOutlet weak var leftPaintBtn: UIButton!
    @IBOutlet weak var rightPaintBtn: UIButton!
    @IBOutlet weak var bottomPaintBtn: UIButton!
    @IBOutlet weak var topPaintBtn: UIButton!
    
    // button filter type3
    @IBOutlet weak var type3LeftBtn: UIButton!
    @IBOutlet weak var type3RightBtn: UIButton!
    @IBOutlet weak var type3TopBtn: UIButton!
    @IBOutlet weak var type3BottomBtn: UIButton!
    
    // button filter type4
    @IBOutlet weak var type4YellowLeftBtn: UIButton!
    @IBOutlet weak var type4GreenLeftBtn: UIButton!
    @IBOutlet weak var type4BlueBottomBtn: UIButton!
    @IBOutlet weak var type4RedBottomBtn: UIButton!
    
    // button filter type5
    @IBOutlet weak var type5GreenBottomBtn: UIButton!
    @IBOutlet weak var type5OrangeLeftBtn: UIButton!
    @IBOutlet weak var type5PurpleBottomBtn: UIButton!
    
    // button filter type2
    @IBOutlet weak var type2BlackTopBtn: UIButton!
    @IBOutlet weak var type2BottomBtn: UIButton!
    @IBOutlet weak var type2PurpleLeftBtn: UIButton!
    @IBOutlet weak var type2BlackBottomBtn: UIButton!
    @IBOutlet weak var type2YelloLeftBtn: UIButton!
    @IBOutlet weak var type2OrangeRightBtn: UIButton!
    @IBOutlet weak var type2BlackRightBtn: UIButton!
    
    
    var designType: DesignType? = .coloringType1 {
        didSet {
            updateLayout()
        }
    }
    
    private var partImageViews: [UIImageView] = []
    private var partOrder: [String] = []
    private var buttonColors: [UIColor] = []
    private var isAnimating = false
    
    // Camera
    private var session: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    private var isUsingFrontCamera = true
    private let videoQueue = DispatchQueue(label: "com.coloring.videoQueue", qos: .userInteractive)
    private let previewImageView = UIImageView()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupButtonRenderingMode()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadFileXib()
        setupView()
        setupPartImageViews()
        updateLayout()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadFileXib()
        setupView()
        setupPartImageViews()
        updateLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func loadFileXib() {
        Bundle.main.loadNibNamed("ColoringView", owner: self, options: nil)
        self.addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
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
        
        if let contentView = contentView {
            bringSubviewToFront(contentView)
        }
    }
    
    // MARK: - Camera Setup
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
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let orientedImage = isUsingFrontCamera ? ciImage.oriented(.leftMirrored) : ciImage.oriented(.right)
        
        if let cgImage = ciContext.createCGImage(orientedImage, from: orientedImage.extent) {
            let uiImage = UIImage(cgImage: cgImage)
            DispatchQueue.main.async { [weak self] in
                self?.previewImageView.image = uiImage
            }
        }
    }
    
    // MARK: - Paint button tapped
    @objc private func buttonTapped(_ sender: UIButton) {
        guard !isAnimating else { return }
            
            var colorIndex: Int
            
            if designType == .coloringType2 {
                // Xử lý riêng cho type 2
                switch sender {
                case type2BlackRightBtn: colorIndex = 0
                case type2BottomBtn: colorIndex = 1
                case type2PurpleLeftBtn: colorIndex = 2
                case type2BlackBottomBtn: colorIndex = 3
                case type2YelloLeftBtn: colorIndex = 4
                case type2OrangeRightBtn: colorIndex = 5
                default: return
                }
            } else {
                // Xử lý cho các type khác
                switch sender {
                case leftPaintBtn, type3LeftBtn, type4GreenLeftBtn,
                    type5OrangeLeftBtn: colorIndex = 0
                case rightPaintBtn, type3RightBtn, type4YellowLeftBtn,
                    type5GreenBottomBtn: colorIndex = 1
                case bottomPaintBtn, type3BottomBtn, type4BlueBottomBtn,
                    type5PurpleBottomBtn: colorIndex = 2
                case topPaintBtn, type3TopBtn, type4RedBottomBtn: colorIndex = 3
                default: return
                }
            }
            
            animatePaintRoller(sender, withColorIndex: colorIndex)
    }
    
    private func animatePaintRoller(_ button: UIButton, withColorIndex colorIndex: Int) {
        guard !isAnimating else { return }
        isAnimating = true
        
        // Tạo bản sao của button để animation
        let buttonCopy = UIButton(frame: button.frame)
        buttonCopy.setImage(button.image(for: .normal), for: .normal)
        buttonCopy.tintColor = button.tintColor
        buttonCopy.contentMode = button.contentMode
        buttonCopy.imageView?.contentMode = button.imageView?.contentMode ?? .scaleAspectFit
        buttonCopy.imageView?.tintColor = button.tintColor
        button.superview?.addSubview(buttonCopy)
        
        // Ẩn button gốc
        button.isHidden = true
        
        let targetPosition: CGPoint
        switch button {
        case leftPaintBtn, type3LeftBtn, type4GreenLeftBtn, type4YellowLeftBtn, type5OrangeLeftBtn, type2PurpleLeftBtn, type2YelloLeftBtn:
            targetPosition = CGPoint(x: paintView.frame.maxX + 50, y: button.center.y)
        case rightPaintBtn, type3RightBtn, type2OrangeRightBtn, type2BlackRightBtn:
            targetPosition = CGPoint(x: paintView.frame.minX - 50, y: button.center.y)
        case topPaintBtn, type3TopBtn, type2BlackTopBtn:
            targetPosition = CGPoint(x: button.center.x, y: paintView.frame.maxY + 50)
        case bottomPaintBtn, type3BottomBtn, type4BlueBottomBtn, type4RedBottomBtn, type5GreenBottomBtn, type5PurpleBottomBtn, type2BottomBtn, type2BlackBottomBtn:
            targetPosition = CGPoint(x: button.center.x, y: paintView.frame.minY - 50)
        default:
            isAnimating = false
            return
        }
        
        UIView.animate(withDuration: 0.5, animations: {
            buttonCopy.center = targetPosition
        }, completion: { [weak self] _ in
            guard let self = self else { return }
            
            // Xóa bản sao
            buttonCopy.removeFromSuperview()
            // Hiện lại button gốc
//            button.isHidden = false
            // Áp dụng màu
            self.applyColor(with: self.buttonColors[colorIndex], for: colorIndex)
            self.isAnimating = false
        })
    }
    
    private func setupButtonRenderingMode() {
        // Type 1 buttons
        leftPaintBtn?.setImage(leftPaintBtn?.image(for: .normal)?.withRenderingMode(.alwaysTemplate), for: .normal)
        rightPaintBtn?.setImage(rightPaintBtn?.image(for: .normal)?.withRenderingMode(.alwaysTemplate), for: .normal)
        topPaintBtn?.setImage(topPaintBtn?.image(for: .normal)?.withRenderingMode(.alwaysTemplate), for: .normal)
        bottomPaintBtn?.setImage(bottomPaintBtn?.image(for: .normal)?.withRenderingMode(.alwaysTemplate), for: .normal)
        
        // Type 3 buttons
        type3LeftBtn?.setImage(type3LeftBtn?.image(for: .normal)?.withRenderingMode(.alwaysTemplate), for: .normal)
        type3RightBtn?.setImage(type3RightBtn?.image(for: .normal)?.withRenderingMode(.alwaysTemplate), for: .normal)
        type3TopBtn?.setImage(type3TopBtn?.image(for: .normal)?.withRenderingMode(.alwaysTemplate), for: .normal)
        type3BottomBtn?.setImage(type3BottomBtn?.image(for: .normal)?.withRenderingMode(.alwaysTemplate), for: .normal)
        
        // Type 2 buttons
        type2BottomBtn?.setImage(type2BottomBtn?.image(for: .normal)?.withRenderingMode(.alwaysTemplate), for: .normal)
        type2BlackTopBtn?.setImage(type2BlackTopBtn?.image(for: .normal)?.withRenderingMode(.alwaysTemplate), for: .normal)
        type2YelloLeftBtn?.setImage(type2YelloLeftBtn?.image(for: .normal)?.withRenderingMode(.alwaysTemplate), for: .normal)
        type2PurpleLeftBtn?.setImage(type2PurpleLeftBtn?.image(for: .normal)?.withRenderingMode(.alwaysTemplate), for: .normal)
        type2BlackBottomBtn?.setImage(type2BlackBottomBtn?.image(for: .normal)?.withRenderingMode(.alwaysTemplate), for: .normal)
        type2OrangeRightBtn?.setImage(type2OrangeRightBtn?.image(for: .normal)?.withRenderingMode(.alwaysTemplate), for: .normal)
        type2BlackRightBtn?.setImage(type2BlackRightBtn?.image(for: .normal)?.withRenderingMode(.alwaysTemplate), for: .normal)
        
        // Type 4 buttons
        type4GreenLeftBtn?.setImage(type4GreenLeftBtn?.image(for: .normal)?.withRenderingMode(.alwaysTemplate), for: .normal)
        type4YellowLeftBtn?.setImage(type4YellowLeftBtn?.image(for: .normal)?.withRenderingMode(.alwaysTemplate), for: .normal)
        type4BlueBottomBtn?.setImage(type4BlueBottomBtn?.image(for: .normal)?.withRenderingMode(.alwaysTemplate), for: .normal)
        type4RedBottomBtn?.setImage(type4RedBottomBtn?.image(for: .normal)?.withRenderingMode(.alwaysTemplate), for: .normal)
        
        // Type 5 buttons
        type5OrangeLeftBtn?.setImage(type5OrangeLeftBtn?.image(for: .normal)?.withRenderingMode(.alwaysTemplate), for: .normal)
        type5GreenBottomBtn?.setImage(type5GreenBottomBtn?.image(for: .normal)?.withRenderingMode(.alwaysTemplate), for: .normal)
        type5PurpleBottomBtn?.setImage(type5PurpleBottomBtn?.image(for: .normal)?.withRenderingMode(.alwaysTemplate), for: .normal)
    }
    
    func updateLayout() {
        guard let designType = designType,
              let config = FilterTypeManager.shared.getConfig(for: designType) else { return }
        
        // Update images
        targetImageView.image = config.targetImage
        paintImageView.image = config.paintImage
        
        // Update button colors
        buttonColors = config.buttonColors
        
        // Update part images
        partOrder = config.partImages
        
        // Clear existing part image views
        for imageView in partImageViews {
            imageView.removeFromSuperview()
        }
        partImageViews.removeAll()
        
        // Setup new part image views with updated partOrder
        setupPartImageViews()
        
        // Reset part image views
        for imageView in partImageViews {
            imageView.tintColor = .clear
        }
        
        // Setup buttons with new colors
        setupButtons()
    }
    
    private func setupPartImageViews() {
        for partName in partOrder {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            if let image = UIImage(named: partName)?.withRenderingMode(.alwaysTemplate) {
                imageView.image = image
                print("Created image view for part: \(partName)")
            } else {
                print("Failed to load image for part: \(partName)")
            }
            imageView.tintColor = .clear
            paintView.insertSubview(imageView, belowSubview: paintImageView)
            
            partImageViews.append(imageView)
            
            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: paintView.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: paintView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: paintView.trailingAnchor),
                imageView.bottomAnchor.constraint(equalTo: paintView.bottomAnchor)
            ])
        }
    }
    
    // MARK: - apply color
    func applyColor(with color: UIColor, for buttonIndex: Int) {
        guard let designType = designType,
              let config = FilterTypeManager.shared.getConfig(for: designType),
              let rule = config.coloringRules[buttonIndex] else { return }
        
        UIView.animate(withDuration: 0.3) {
            switch rule {
            case .singlePart(let partIndex):
                if self.partImageViews.count > partIndex {
                    self.partImageViews[partIndex].tintColor = color
                }
            case .multipleParts(let partIndices):
                for index in partIndices where index < self.partImageViews.count {
                    self.partImageViews[index].tintColor = color
                }
            case .allParts:
                for imageView in self.partImageViews {
                    imageView.tintColor = color
                }
            }
        }
    }
    
    func resetToInitialState() {
        // Reset part image views
        for imageView in partImageViews {
            imageView.tintColor = .clear
        }
        
        // Hiện lại tất cả button của filter type hiện tại
        setupButtons()
    }
}

// MARK: - Setup
extension ColoringView {
    private func setupButtons() {
        guard let designType = designType,
              let config = FilterTypeManager.shared.getConfig(for: designType) else { return }
        
        // Hide all buttons first
        hideAllButtons()
        
        switch designType {
        case .coloringType1:
            setupType1Buttons(config)
        case .coloringType2:
            setupType2Buttons(config)
        case .coloringType3:
            setupType3Buttons(config)
        case .coloringType4:
            setupType4Buttons(config)
        case .coloringType5:
            setupType5Buttons(config)
        default:
            break
        }
    }
    
    private func hideAllButtons() {
        leftPaintBtn?.isHidden = true
        rightPaintBtn?.isHidden = true
        topPaintBtn?.isHidden = true
        bottomPaintBtn?.isHidden = true
        
        type2BlackTopBtn?.isHidden = true
        type2BottomBtn?.isHidden = true
        type2PurpleLeftBtn?.isHidden = true
        type2BlackBottomBtn?.isHidden = true
        type2YelloLeftBtn?.isHidden = true
        type2OrangeRightBtn?.isHidden = true
        type2BlackRightBtn.isHidden = true
        
        type3LeftBtn?.isHidden = true
        type3RightBtn?.isHidden = true
        type3TopBtn?.isHidden = true
        type3BottomBtn?.isHidden = true
        
        type4GreenLeftBtn?.isHidden = true
        type4YellowLeftBtn?.isHidden = true
        type4BlueBottomBtn?.isHidden = true
        type4RedBottomBtn?.isHidden = true
        
        type5OrangeLeftBtn.isHidden = true
        type5GreenBottomBtn.isHidden = true
        type5PurpleBottomBtn.isHidden = true
    }
    
    private func setupType1Buttons(_ config: FilterTypeConfig) {
        if let leftBtn = leftPaintBtn {
            leftBtn.isHidden = false
            leftBtn.tintColor = config.buttonColors[0]
            leftBtn.imageView?.contentMode = .scaleAspectFit
            leftBtn.imageView?.tintColor = config.buttonColors[0]
            leftBtn.tag = 0
            leftBtn.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            print("Type1 Left button color: \(config.buttonColors[0])")
        }
        if let rightBtn = rightPaintBtn {
            rightBtn.isHidden = false
            rightBtn.tintColor = config.buttonColors[1]
            rightBtn.imageView?.contentMode = .scaleAspectFit
            rightBtn.imageView?.tintColor = config.buttonColors[1]
            rightBtn.tag = 1
            rightBtn.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            print("Type1 Right button color: \(config.buttonColors[1])")
        }
        if let topBtn = topPaintBtn {
            topBtn.isHidden = false
            topBtn.tintColor = config.buttonColors[2]
            topBtn.imageView?.contentMode = .scaleAspectFit
            topBtn.imageView?.tintColor = config.buttonColors[2]
            topBtn.tag = 2
            topBtn.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            print("Type1 Top button color: \(config.buttonColors[3])")
        }
        if let bottomBtn = bottomPaintBtn {
            bottomBtn.isHidden = false
            bottomBtn.tintColor = config.buttonColors[3]
            bottomBtn.imageView?.contentMode = .scaleAspectFit
            bottomBtn.imageView?.tintColor = config.buttonColors[3]
            bottomBtn.tag = 3
            bottomBtn.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            print("Type1 Bottom button color: \(config.buttonColors[2])")
        }
    }
    
    private func setupType2Buttons(_ config: FilterTypeConfig) {
        if let blackTopBtn = type2BlackRightBtn {
            blackTopBtn.isHidden = false
            blackTopBtn.tintColor = config.buttonColors[0]
            blackTopBtn.imageView?.contentMode = .scaleAspectFit
            blackTopBtn.imageView?.tintColor = config.buttonColors[0]
            blackTopBtn.tag = 0
            blackTopBtn.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        }
        
        if let bottomBtn = type2BottomBtn {
            bottomBtn.isHidden = false
            bottomBtn.tintColor = config.buttonColors[1]
            bottomBtn.imageView?.contentMode = .scaleAspectFit
            bottomBtn.imageView?.tintColor = config.buttonColors[1]
            bottomBtn.tag = 1
            bottomBtn.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        }
        
        if let purpleLeftBtn = type2PurpleLeftBtn {
            purpleLeftBtn.isHidden = false
            purpleLeftBtn.tintColor = config.buttonColors[2]
            purpleLeftBtn.imageView?.contentMode = .scaleAspectFit
            purpleLeftBtn.imageView?.tintColor = config.buttonColors[2]
            purpleLeftBtn.tag = 2
            purpleLeftBtn.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        }
        
        if let blackBottomBtn = type2BlackBottomBtn {
            blackBottomBtn.isHidden = false
            blackBottomBtn.tintColor = config.buttonColors[3]
            blackBottomBtn.imageView?.contentMode = .scaleAspectFit
            blackBottomBtn.imageView?.tintColor = config.buttonColors[3]
            blackBottomBtn.tag = 3
            blackBottomBtn.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        }
        
        if let yellowLeftBtn = type2YelloLeftBtn {
            yellowLeftBtn.isHidden = false
            yellowLeftBtn.tintColor = config.buttonColors[4]
            yellowLeftBtn.imageView?.contentMode = .scaleAspectFit
            yellowLeftBtn.imageView?.tintColor = config.buttonColors[4]
            yellowLeftBtn.tag = 4
            yellowLeftBtn.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        }
        
        if let orangeRightBtn = type2OrangeRightBtn {
            orangeRightBtn.isHidden = false
            orangeRightBtn.tintColor = config.buttonColors[5]
            orangeRightBtn.imageView?.contentMode = .scaleAspectFit
            orangeRightBtn.imageView?.tintColor = config.buttonColors[5]
            orangeRightBtn.tag = 5
            orangeRightBtn.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        }
    }
    
    private func setupType3Buttons(_ config: FilterTypeConfig) {
        if let leftBtn = type3LeftBtn {
            leftBtn.isHidden = false
            leftBtn.tintColor = config.buttonColors[0]
            leftBtn.imageView?.contentMode = .scaleAspectFit
            leftBtn.imageView?.tintColor = config.buttonColors[0]
            leftBtn.tag = 0
            leftBtn.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            print("Type3 Left button color: \(config.buttonColors[0])")
        }
        if let rightBtn = type3RightBtn {
            rightBtn.isHidden = false
            rightBtn.tintColor = config.buttonColors[1]
            rightBtn.imageView?.contentMode = .scaleAspectFit
            rightBtn.imageView?.tintColor = config.buttonColors[1]
            rightBtn.tag = 1
            rightBtn.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            print("Type3 Right button color: \(config.buttonColors[1])")
        }
        if let topBtn = type3TopBtn {
            topBtn.isHidden = false
            topBtn.tintColor = config.buttonColors[2]
            topBtn.imageView?.contentMode = .scaleAspectFit
            topBtn.imageView?.tintColor = config.buttonColors[2]
            topBtn.tag = 2
            topBtn.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            print("Type3 Top button color: \(config.buttonColors[2])")
        }
        if let bottomBtn = type3BottomBtn {
            bottomBtn.isHidden = false
            bottomBtn.tintColor = config.buttonColors[3]
            bottomBtn.imageView?.contentMode = .scaleAspectFit
            bottomBtn.imageView?.tintColor = config.buttonColors[3]
            bottomBtn.tag = 3
            bottomBtn.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            print("Type3 Bottom button color: \(config.buttonColors[3])")
        }
    }
    
    private func setupType4Buttons(_ config: FilterTypeConfig) {
        if let greenBtn = type4GreenLeftBtn {
            greenBtn.isHidden = false
            greenBtn.tintColor = config.buttonColors[0]
            greenBtn.imageView?.contentMode = .scaleAspectFit
            greenBtn.imageView?.tintColor = config.buttonColors[0]
            greenBtn.tag = 0
            greenBtn.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        }
        
        if let yellowBtn = type4YellowLeftBtn {
            yellowBtn.isHidden = false
            yellowBtn.tintColor = config.buttonColors[1]
            yellowBtn.imageView?.contentMode = .scaleAspectFit
            yellowBtn.imageView?.tintColor = config.buttonColors[1]
            yellowBtn.tag = 1
            yellowBtn.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        }
        
        if let blueBtn = type4BlueBottomBtn {
            blueBtn.isHidden = false
            blueBtn.tintColor = config.buttonColors[2]
            blueBtn.imageView?.contentMode = .scaleAspectFit
            blueBtn.imageView?.tintColor = config.buttonColors[2]
            blueBtn.tag = 2
            blueBtn.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        }
        
        if let redBtn = type4RedBottomBtn {
            redBtn.isHidden = false
            redBtn.tintColor = config.buttonColors[3]
            redBtn.imageView?.contentMode = .scaleAspectFit
            redBtn.imageView?.tintColor = config.buttonColors[3]
            redBtn.tag = 3
            redBtn.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        }
    }
    
    private func setupType5Buttons(_ config: FilterTypeConfig) {
        if let orangeBtn = type5OrangeLeftBtn {
            orangeBtn.isHidden = false
            orangeBtn.tintColor = config.buttonColors[0]
            orangeBtn.imageView?.contentMode = .scaleAspectFit
            orangeBtn.imageView?.tintColor = config.buttonColors[0]
            orangeBtn.tag = 0
            orangeBtn.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        }
        
        if let greenBtn = type5GreenBottomBtn {
            greenBtn.isHidden = false
            greenBtn.tintColor = config.buttonColors[1]
            greenBtn.imageView?.contentMode = .scaleAspectFit
            greenBtn.imageView?.tintColor = config.buttonColors[1]
            greenBtn.tag = 1
            greenBtn.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        }
        
        if let purpleBtn = type5PurpleBottomBtn {
            purpleBtn.isHidden = false
            purpleBtn.tintColor = config.buttonColors[2]
            purpleBtn.imageView?.contentMode = .scaleAspectFit
            purpleBtn.imageView?.tintColor = config.buttonColors[2]
            purpleBtn.tag = 2
            purpleBtn.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        }
    }
}
