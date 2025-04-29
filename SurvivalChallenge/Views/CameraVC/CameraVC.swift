//
//  CameraVC.swift
//  SurvivalChallenge
//
//  Created by Apple on 14/4/25.
//

import UIKit
import AVFoundation
import Stevia
import MLKitFaceDetection
import MLKit
import SDWebImage

class CameraVC: UIViewController {
    @IBOutlet weak var rankingView: RankingView!
    @IBOutlet weak var guessView: GuessView!
    @IBOutlet weak var bgCameraView: UIView!
    @IBOutlet weak var addMusicBtn: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var selectMusicView: UIView!
    @IBOutlet weak var musicTitleLB: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var filterView: FilterModeView!
    @IBOutlet weak var cameraButton: UIView!
    @IBOutlet weak var rightDeleteButtonConstraint: NSLayoutConstraint!
    @IBOutlet weak var widthDeleteButtonConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var discardButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var timeLB: UILabel!
    
    private var progressView: CircularProgressView!
    
    var coloringView: ColoringView?
    var designType: DesignType?
    var filterType: FilterType?
    var selectedChallenge: SurvivalChallengeEntity?
    var currentChallenge: SurvivalChallengeEntity?
    
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private lazy var musicView = MusicView()
    private lazy var overlayView = UIView()
    var isAccessCamera: Bool = false
    var challenges: [SurvivalChallengeEntity] = []
    
    private var isMusicViewVisible: Bool = false {
        didSet {
            updateMusicUI()
        }
    }

    private var isInNaviStack = false
    private var isPop = false
    private var hasMusic = false
    private var isFlashOn = false
    private var originalBrightness: CGFloat = 0.0
    
    private let audioQueue = DispatchQueue(label: "com.nhanho.audioQueue")
    private var audioPlayer: AVPlayer?
    
    private let sessionQueue = DispatchQueue(label: "com.nhanho.sessionQueue")
    private var captureSession = AVCaptureSession()
    private var isUsingFrontCamera = true
    private var timer: Timer?
    private var recordedTime: TimeInterval = 0
    private var startTime: Date?
    private var accumulatedTime: TimeInterval = 0
    private var recordingState: RecordingState = .notRecording
    private var videoComposer: VideoComposer!
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupColoringView()
        updateActiveView()
        setupTapGesture()
        setupCamera()
        setupVideoComposer()
        resetMusicSelection()
        setupHandles()
        
        let audioItems = HomeViewModel.shared.audioItems
        print("yolo Audio items: \(audioItems)")
        musicView.setAudioItems(audioItems)
        
        print("yolo Challenges received in CameraVC: \(challenges.count)")
        filterView.challenges = challenges
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkCameraPermission()
        resetState()
        
        if isAccessCamera {
            if !captureSession.isRunning {
                DispatchQueue.global().async { [weak self] in
                    guard let self = self else { return }
                    startSession()
                }
            }
        }
        
        if let selectedChallenge = selectedChallenge {
            if let index = challenges.firstIndex(where: { $0.id == selectedChallenge.id }) {
                print("yolo Scrolling to selected challenge index: \(index), name: \(selectedChallenge.name)")
                filterView.scrollToItem(at: index)
            } else {
                print("yolo Selected challenge not found in challenges, defaulting to index 0")
                filterView.scrollToItem(at: 0)
            }
        } else {
            print("yolo No selected challenge, scrolling to index 0")
            filterView.scrollToItem(at: 0)
        }
        
        if isInNaviStack {
            if hasMusic {
                audioQueue.async { [weak self] in
                    guard let self = self else { return }
                    audioPlayer?.play()
                }
            }
            accumulatedTime = recordedTime
            videoComposer?.validateSegments()
            videoComposer?.resetComposer()
            
            if isFlashOn {
                if isUsingFrontCamera {
                    originalBrightness = UIScreen.main.brightness
                    UIScreen.main.brightness = 1.0
                } else {
                    turnOnTorch()
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resetAllDetectionState()
        if isAccessCamera {
            if captureSession.isRunning {
                stopSession()
            }
        }
        clear()
    }
        
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if previewLayer != nil {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                previewLayer.frame = bgCameraView.bounds
            }
        }
    }
    
    @IBAction func didTapAddMusicBtn(_ sender: Any) {
        isMusicViewVisible.toggle()
    }
    
    @IBAction func didTapBackBtn(_ sender: Any) {
        isPop = true
        navigationController?.popToRootViewController(animated: false)
    }
    
    @IBAction func didTapChangeCameraBtn(_ sender: Any) {
        let wasRecording = recordingState == .recording
        if wasRecording {
            pauseRecording()
        }
            
        isUsingFrontCamera.toggle()
        setUpCaptureSessionInput()
        
        // Đảm bảo các view được cập nhật session mới
        updateRankingViewSession()
        updateGuessViewSession()
            
            // Tiếp tục recording nếu trước đó đang recording
        if wasRecording {
            resumeRecording()
        }
    }
    
    @IBAction func didTapLightningBtn(_ sender: Any) {
        isFlashOn.toggle()
        updateFlashlightButton()
        
        if isFlashOn {
            if isUsingFrontCamera {
                originalBrightness = UIScreen.main.brightness
                UIScreen.main.brightness = 1.0
            } else {
                turnOnTorch()
            }
        } else {
            if isUsingFrontCamera {
                UIScreen.main.brightness = originalBrightness
                turnOffTorch()
            } else {
                turnOffTorch()
            }
        }
    }
    
    @IBAction func didTapMagicBtn(_ sender: Any) {
        let selectFilterVC = SelectFilterVC()
        selectFilterVC.delegate = self
        navigationController?.pushViewController(selectFilterVC, animated: false)
    }
    
    @IBAction func didTapDeleteMusicBtn(_ sender: Any) {
        resetMusicSelection()
    }
    
    @IBAction func didTapSaveBtn(_ sender: Any) {
        stopRecording()
    }
    
    @IBAction func didTapDiscardBtn(_ sender: Any) {
        let alert = UIAlertController(title: "Discard your video?", message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Discard", style: .destructive, handler: { _ in
            self.progressView.discardLastSegment()
            self.videoComposer.discardLastSegment()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    private func setupVideoComposer() {
        let width = 540
        let height = 960
        videoComposer = VideoComposer(width: width, height: height)
    }
}

// MARK: - Reset Methods
extension CameraVC {
    private func resetState() {
        recordedTime = 0
        accumulatedTime = 0
        startTime = nil
        timer?.invalidate()
        timer = nil
        recordingState = .notRecording
        rankingView?.resetState()
        guessView?.resetState()
        updateTimeLabel()
        updateUIWhenResetRecord()
        print("yolo CameraVC state reset")
    }
    
    private func resetAllDetectionState() {
        rankingView?.resetState()
        guessView?.resetState()
        print("yolo All detection states reset")
    }
}

// MARK: - Functions
extension CameraVC {
    // MARK: - Handles
    private func setupHandles() {
        progressView.onCompletion = { [weak self] in
            guard let self else { return }
            
            print("⚙️ Done recording")
            self.pauseRecording()
            self.recordingState = .notRecording
            self.updateUIWhenPauseRecord()
        }
        
        progressView.onPause = { [weak self] isPaused in
            guard let self else { return }
            if isPaused {
                pauseRecording()
            } else {
                resumeRecording()
            }
        }
        
        progressView.onReset = { [weak self] in
            guard let self else { return }
            self.recordedTime = 0
            self.recordingState = .notRecording
            self.updateUIWhenResetRecord()
            self.updateTimeLabel()
            self.videoComposer.cancelAllRecordings()
        }
        
        progressView.onTimeUpdated = { [weak self] newTime in
            guard let self = self else { return }
            self.recordedTime = newTime
            self.accumulatedTime = newTime
            self.updateTimeLabel()
        }
    }
    
    private func clear() {
        turnOffTorch()
        if isPop {
            timer?.invalidate()
            timer = nil
            videoComposer = nil
            audioPlayer = nil
            progressView = nil
        }
    }
    
    private func turnOffTorch() {
        sessionQueue.async {
            guard let device = AVCaptureDevice.default(for: .video) else { return }
            do {
                try device.lockForConfiguration()
                if device.hasTorch {
                    device.torchMode = .off
                }
                device.unlockForConfiguration()
            } catch {
                print("Error turning off torch: \(error)")
            }
        }
    }
    
    private func turnOnTorch() {
        sessionQueue.async {
            guard let device = AVCaptureDevice.default(for: .video) else { return }
            do {
                try device.lockForConfiguration()
                if device.hasTorch {
                    try device.setTorchModeOn(level: 1.0)
                }
                device.unlockForConfiguration()
            } catch {
                print("Error turning on torch: \(error)")
            }
        }
    }
    
    private func updateUIWhenStartRecord() {
        self.progressView.isHidden = false
        self.progressView.alpha = 0
        self.timeLB.isHidden = false
        self.timeLB.alpha = 0
        UIView.animate(withDuration: 0.3, animations: {
            self.flashButton.alpha = 0
            self.filterView.alpha = 0
            self.progressView.alpha = 1
            self.timeLB.alpha = 1
        }, completion: { _ in
            self.flashButton.isHidden = true
            self.filterView.isHidden = true
            
            self.saveButton.isHidden = false
            self.saveButton.alpha = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: {
                UIView.animate(withDuration: 0.3, animations: {
                    self.saveButton.alpha = 1
                })
            })
        })
    }
    
    private func updateUIWhenPauseRecord() {
        self.flashButton.isHidden = false
        self.discardButton.isHidden = false
        self.discardButton.alpha = 0
        UIView.animate(withDuration: 0.3, animations: {
            self.flashButton.alpha = 1
            self.discardButton.alpha = 1
        })
    }
    
    private func updateUIWhenResumeRecord() {
        UIView.animate(withDuration: 0.3, animations: {
            self.flashButton.alpha = 0
            self.discardButton.alpha = 0
        }, completion: { _ in
            self.flashButton.isHidden = true
            self.discardButton.isHidden = true
        })
    }
    
    private func updateUIWhenResetRecord() {
        self.flashButton.isHidden = false
        self.filterView.isHidden = false
        
        UIView.animate(withDuration: 0.3, animations: {
            self.flashButton.alpha = 1
            self.filterView.alpha = 1
            self.progressView.alpha = 0
            self.discardButton.alpha = 0
            self.saveButton.alpha = 0
            self.timeLB.alpha = 0
        }, completion: { _ in
            self.progressView.isHidden = true
            self.discardButton.isHidden = true
            self.saveButton.isHidden = true
            self.timeLB.isHidden = true
        })
    }
}

extension CameraVC {
    private func createVideo(from image: UIImage, audioURL: URL?) async -> URL? {
        await withCheckedContinuation { continuation in
            VideoComposer.createVideo(from: image, with: audioURL) { videoURL in
                continuation.resume(returning: videoURL)
            }
        }
    }
    
    private func updateTimeLabel() {
        let total = Int(recordedTime)
        let minutes = total / 60
        let seconds = total % 60
        timeLB.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func startRecording() {
        guard recordingState == .notRecording else { return }
        
        if videoComposer == nil {
            let sessionPreset = captureSession.sessionPreset
            let width, height: Int
            if sessionPreset == .hd1920x1080 {
                width = 720
                height = 1280
            } else {
                width = 540
                height = 960
            }
            videoComposer = VideoComposer(width: width, height: height)
        }
        
        if let filterType = filterType {
            switch filterType {
            case .ranking:
                videoComposer.setEffectType(filterType, designType: designType, view: rankingView!)
            case .guess:
                videoComposer.setEffectType(filterType, designType: designType, view: guessView!)
            case .coloring:
                videoComposer.setEffectType(filterType, designType: designType, view: coloringView!)
            default:
                videoComposer.setEffectType(.none, designType: nil, view: bgCameraView)
            }
        }
        
        videoComposer.startRecording()
        recordingState = .recording
        
        DispatchQueue.main.async {
            self.updateUIWhenStartRecord()
            self.progressView.startProgress(duration: 60)
        }
        
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            audioPlayer?.seek(to: .zero)
            audioPlayer?.play()
        }
        
        accumulatedTime = 0
        startTime = Date()
        recordedTime = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.recordingState == .recording else { return }
            let currentSegmentTime = Date().timeIntervalSince(self.startTime!)
            self.recordedTime = self.accumulatedTime + currentSegmentTime
            self.updateTimeLabel()
        }
    }
    
    private func pauseRecording() {
        if let startTime = self.startTime {
            accumulatedTime += Date().timeIntervalSince(startTime)
        }
        
        recordingState = .paused
        updateUIWhenPauseRecord()
        
        videoComposer.pauseRecording()
        timer?.invalidate()
        timer = nil
    }
    
    private func resumeRecording() {
        videoComposer.resumeRecording()
        startTime = Date()
        recordingState = .recording
        updateUIWhenResumeRecord()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.recordingState == .recording else { return }
            let currentSegmentTime = Date().timeIntervalSince(self.startTime!)
            self.recordedTime = self.accumulatedTime + currentSegmentTime
            self.updateTimeLabel()
        }
    }
    
    private func stopRecording() {
        timer?.invalidate()
        timer = nil
        recordingState = .paused
        
        updateUIWhenPauseRecord()
        if !progressView.isPaused {
            progressView.pauseProgress()
        }
        
        Utils.showIndicator()
        
        videoComposer.finalizeAndExportVideo { [weak self] url in
            Task {
                guard let self = self, let videoUrl = url else {
                    DispatchQueue.main.async {
                        Utils.showAlertOK(title: "Error", message: "Failed to create video")
                        Utils.removeIndicator()
                    }
                    return
                }
                
                Utils.removeIndicator()
                let resultVC = ResultVC()
                resultVC.videoURL = videoUrl
                self.isInNaviStack = true
                self.navigationController?.pushViewController(resultVC, animated: true)
            }
        }
    }
}

// MARK: - Helper Methods
extension CameraVC {
    private func resetMusicSelection() {
        musicTitleLB.text = Localized.Camera.addMusic
        deleteButton.isHidden = true
        rightDeleteButtonConstraint.constant = 0
        widthDeleteButtonConstraint.constant = 0
        musicView.stopAudio()
        musicView.resetPlaybackState()
    }
    
    private func updateRankingViewSession() {
        if filterType == .ranking && rankingView != nil {
            rankingView?.setPreviewSession(captureSession, isUsingFrontCamera)
        }
    }
    
    private func updateGuessViewSession() {
        if filterType == .guess {
            guessView?.setPreviewSession(captureSession, isUsingFrontCamera)
        }
    }
}

// MARK: - Setup View
extension CameraVC {
    func setupViews() {
        rankingView.delegate = self
        filterView.delegate = self
        view.subviews {
            overlayView
            musicView
        }
        
        musicView
            .left(0)
            .right(0)
            .bottom(0)
            .height(407)
        
        progressView = CircularProgressView()
        view.addSubview(progressView)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progressView.centerXAnchor.constraint(equalTo: cameraButton.centerXAnchor),
            progressView.centerYAnchor.constraint(equalTo: cameraButton.centerYAnchor),
            progressView.widthAnchor.constraint(equalToConstant: 80),
            progressView.heightAnchor.constraint(equalToConstant: 80)
        ])
        progressView.isHidden = true
        
        discardButton.isHidden = true
        saveButton.isHidden = true
        timeLB.isHidden = true
        
        musicView.style {
            $0.backgroundColor = .white
            $0.isHidden = true
            $0.transform = CGAffineTransform(translationX: 0, y: $0.frame.height)
            $0.layer.cornerRadius = 20
            $0.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
            $0.clipsToBounds = true
            $0.delegate = self
        }
        
        overlayView.style {
            $0.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            $0.fillContainer()
            $0.isHidden = true
        }
        
        selectMusicView.style {
            $0.clipsToBounds = true
            $0.layer.cornerRadius = $0.frame.height / 2
            $0.clipsToBounds = true
            $0.layoutIfNeeded()
        }
        
        musicTitleLB.style {
            $0.font = UIFont.sfProDisplayBold(ofSize: 13)
            $0.textColor = .white
        }
        
        addMusicBtn.style {
            var config = UIButton.Configuration.borderedProminent()
            config.baseBackgroundColor = .hex212121.withAlphaComponent(0.65)
            config.baseForegroundColor = .white
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = UIFont.sfProDisplayBold(ofSize: 13)
                return outgoing
            }
            config.contentInsets = NSDirectionalEdgeInsets(
                top: 5,
                leading: 0,
                bottom: 5,
                trailing: 0
            )
            config.cornerStyle = .capsule
            
            $0.configuration = config
            $0.titleLabel?.text = Localized.Camera.addMusic
            $0.clipsToBounds = true
        }
        
        cameraButton.style {
            $0.backgroundColor = .clear
            $0.layer.borderColor = UIColor.white.cgColor
            $0.layer.borderWidth = 5.0
            $0.layer.cornerRadius = 40
            $0.isUserInteractionEnabled = true
        }
    }

    // MARK: - Setup ColoringView
    func setupColoringView() {
        guard coloringView == nil else { return }
        guard let coloringView = Bundle.main.loadNibNamed("ColoringView", owner: self, options: nil)?.first as? ColoringView else {
            print("Failed to load ColoringView")
            return
        }
        self.coloringView = coloringView
        coloringView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(coloringView)
        
        coloringView
            .fillHorizontally()
        coloringView.Top == addMusicBtn.Bottom + 50
        coloringView.Bottom == filterView.Top - 10
        
        coloringView.isHidden = true
        print("ColoringView initialized")
    }
    
    func updateActiveView() {
        print("yolo Filter Type: \(String(describing: filterType)), Design Type: \(String(describing: designType))")
        
        // Deactivate all views first
        rankingView?.deactivate()
        guessView?.deactivate()
        
        // Hide all views first
        rankingView?.isHidden = true
        guessView?.isHidden = true
        coloringView?.isHidden = true
        
        // Làm trong suốt bgCameraView để phát hiện vấn đề
        bgCameraView.backgroundColor = UIColor.clear
        
        guard let filterType = filterType else {
            print("No filter type selected.")
            return
        }
        
        // Thêm log rõ ràng
        print("yolo Activating filter: \(filterType)")
        
        // Đảm bảo previewLayer được cập nhật
        if previewLayer != nil {
            previewLayer.frame = bgCameraView.bounds
        }
        
        switch filterType {
        case .ranking:
            print("yolo Showing RankingView")
            rankingView?.isHidden = false
            if let designType = designType {
                rankingView?.designType = designType
            }
            
            // Thêm delay để tránh race condition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let self = self else { return }
                print("yolo Setting RankingView session and activating")
                self.rankingView?.setPreviewSession(self.captureSession, self.isUsingFrontCamera)
                self.rankingView?.activate() // Đảm bảo kích hoạt view
                if let challenge = self.currentChallenge {
                    print("yolo Setting challenge for RankingView: \(challenge.name)")
                    self.rankingView?.setChallenge(challenge)
                } else {
                    print("yolo Warning: No challenge available for RankingView")
                }
            }
            
        case .guess:
            print("yolo Showing GuessView")
            guessView?.isHidden = false
            if let designType = designType {
                guessView?.designType = designType
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let self = self else { return }
                print("yolo Setting GuessView session and activating")
                self.guessView?.setPreviewSession(self.captureSession, self.isUsingFrontCamera)
                self.guessView?.activate() // Đảm bảo kích hoạt view
                if let challenge = self.currentChallenge {
                    print("yolo Setting challenge for GuessView: \(challenge.name)")
                    self.guessView?.setChallenge(challenge)
                } else {
                    print("yolo Warning: No challenge available for GuessView")
                }
            }
            
        case .coloring:
            print("yolo Showing ColoringView")
            coloringView?.isHidden = false
            if let designType = designType {
                coloringView?.designType = designType
            }
            
        default:
            print("No valid filter type.")
        }
        
        view.layoutIfNeeded() // Buộc layout cập nhật
        
        if videoComposer != nil {
            switch filterType {
            case .ranking:
                videoComposer.setEffectType(filterType, designType: designType, view: rankingView!)
            case .guess:
                videoComposer.setEffectType(filterType, designType: designType, view: guessView!)
            case .coloring:
                videoComposer.setEffectType(filterType, designType: designType, view: coloringView!)
            default:
                videoComposer.setEffectType(filterType, designType: designType, view: bgCameraView)
            }
        }
    }
}

// MARK: - Tap Gesture
extension CameraVC {
    func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tapGesture)
        tapGesture.cancelsTouchesInView = false
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        musicView.addGestureRecognizer(panGesture)
        
        let selectMusicTapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(didTapSelectMusicView(_:)))
        selectMusicView.addGestureRecognizer(selectMusicTapGesture)
    }
    
    @objc func handleTap(_ gesture: UIGestureRecognizer) {
        let location = gesture.location(in: view)
        
        if !musicView.isHidden && !musicView.frame.contains(location) {
            isMusicViewVisible = false
        }
    }
    
    @objc func didTapSelectMusicView(_ gesture: UITapGestureRecognizer) {
        // Check if the tap was within the bounds of the delete button
        let tapLocation = gesture.location(in: selectMusicView)
        if deleteButton.isHidden || !deleteButton.frame.contains(tapLocation) {
            // If not on the delete button, toggle the music view visibility
            isMusicViewVisible.toggle()
        }
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .changed:
            if translation.y > 0 {
                musicView.transform = CGAffineTransform(translationX: 0, y: translation.y)
            }
        case .ended:
            if translation.y > musicView.frame.height / 3 || velocity.y > 1000 {
                isMusicViewVisible = false
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.musicView.transform = .identity
                }
            }
        default:
            break
        }
    }
}

// MARK: - Music UI
extension CameraVC {
    func updateMusicUI() {
        if isMusicViewVisible {
            overlayView.isHidden = false
            musicView.isHidden = false
            UIView.animate(withDuration: 0.3) {
                self.musicView.transform = .identity
            }
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                self.musicView.transform = CGAffineTransform(translationX: 0, y: self.musicView.frame.height)
            }) { _ in
                self.musicView.isHidden = true
                self.overlayView.isHidden = true
            }
        }
    }
}

// MARK: - Detect Camera
extension CameraVC: AVCaptureVideoDataOutputSampleBufferDelegate {
    private func setupPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = bgCameraView.bounds
        bgCameraView.layer.addSublayer(previewLayer)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if recordingState == .recording {
            videoComposer.processSampleBuffer(sampleBuffer)
        }
    }
}

// MARK: - Setup Capture Camera
extension CameraVC {
    private func captureDevice(forPosition position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified)
        return discoverySession.devices.first { $0.position == position }
    }
    
    private func setUpCaptureSessionInput() {
        sessionQueue.async {
            guard let device = self.captureDevice(forPosition: self.isUsingFrontCamera ? .front : .back) else {
                print("💀Failed to get capture device for camera position: \(self.isUsingFrontCamera ? "front" : "back")")
                return
            }
            do {
                self.captureSession.beginConfiguration()
                let currentInputs = self.captureSession.inputs
                for input in currentInputs {
                    self.captureSession.removeInput(input)
                }
                
                let input = try AVCaptureDeviceInput(device: device)
                guard self.captureSession.canAddInput(input) else {
                    print("Failed to add capture session input.")
                    return
                }
                self.captureSession.addInput(input)
                self.captureSession.commitConfiguration()
            } catch {
                print("Failed to create capture device input: \(error.localizedDescription)")
            }
        }
    }
    
    private func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
        }
    }
        
    private func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
        }
    }
    
    private func setupCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.captureSession.beginConfiguration()
            
            DispatchQueue.main.async {
                self.setupPreviewLayer()
            }
            
            if self.captureSession.canSetSessionPreset(.hd1920x1080) == true {
                self.captureSession.sessionPreset = .hd1920x1080
            } else if self.captureSession.canSetSessionPreset(.high) == true {
                self.captureSession.sessionPreset = .high
            } else {
                self.captureSession.sessionPreset = .medium
            }
            
            if let currentInputs = self.captureSession.inputs as? [AVCaptureDeviceInput] {
                for input in currentInputs {
                    self.captureSession.removeInput(input)
                }
            }
            
            guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
                print("Unable to access front camera!")
                self.captureSession.commitConfiguration()
                return
            }
            
            do {
                let input = try AVCaptureDeviceInput(device: frontCamera)
                
                if self.captureSession.canAddInput(input) == true {
                    self.captureSession.addInput(input)
                }
                
                //set videoOutputDelegate
                let videoOutput = AVCaptureVideoDataOutput()
                videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.nhanhoo.camera.videoQueue"))
                if self.captureSession.canAddOutput(videoOutput) == true {
                    self.captureSession.addOutput(videoOutput)
                }
            } catch {
                print("Error Unable to initialize back camera: \(error.localizedDescription)")
            }
            
            self.captureSession.commitConfiguration()
        }
    }
        
    private func checkCameraPermission() {
        UserDefaultsManager.shared.onResumeCanLoad = false
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            UserDefaultsManager.shared.onResumeCanLoad = true
            isAccessCamera = true
            startSession()
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self = self else { return }
                
                UserDefaultsManager.shared.onResumeCanLoad = true
                if granted {
                    self.isAccessCamera = true
                    DispatchQueue.main.async {
                        self.startSession()
                    }
                } else {
                    self.isAccessCamera = false
                    DispatchQueue.main.async {
                        Utils.showCameraSettingsAlert()
                    }
                }
            }
            
        case .denied, .restricted:
            UserDefaultsManager.shared.onResumeCanLoad = true
            isAccessCamera = false
            Utils.showCameraSettingsAlert()
            
        @unknown default:
            UserDefaultsManager.shared.onResumeCanLoad = true
            break
        }
    }
        
    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "Camera Access Required",
            message: "Please enable camera access in Settings to record video",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        self.present(alert, animated: true)
    }
    
    private func toggleFlashlight() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = device.torchMode == .on ? .off : .on
            device.unlockForConfiguration()
            updateFlashlightButton()
        } catch {
            debugPrint("Error toggling flashlight")
        }
    }
    
    private func updateFlashlightButton() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        let imageName = device.torchMode == .on ? UIImage.lightningOffIc : UIImage.lightningOnIc
        flashButton.setImage(imageName, for: .normal)
    }
}

// MARK: - MusicViewDelegate
extension CameraVC: MusicViewDelegate {
    func didSelectMusic(title: String) {
        musicTitleLB.text = title
        rightDeleteButtonConstraint.constant = 18
        widthDeleteButtonConstraint.constant = 16
        deleteButton.isHidden = false
    }
}

extension CameraVC: SelectFilterDelegate {
    func didSelectFilter(at index: Int) {
        
    }
}

// MARK: - FilterMode
extension CameraVC: FilterModeDelegate {
    func selectedFocusItem() {
        startRecording()
    }
    
    func getSelectedFocusItem(filter: FilterType, designType: DesignType?, challenge: SurvivalChallengeEntity?) {
        print("yolo Selected filter: \(filter), design: \(String(describing: designType)), challenge: \(challenge?.name ?? "nil")")
            
        // Lưu trữ trạng thái cũ
        let oldFilter = self.filterType
        
        // Đặt giá trị mới
        self.filterType = filter
        self.designType = designType
        self.currentChallenge = challenge
        
        // Nếu filter thay đổi, reset state các view
        if oldFilter != filter {
            // Ẩn tất cả view trước
            rankingView?.isHidden = true
            guessView?.isHidden = true
            coloringView?.isHidden = true
            
            // Deactivate các view cũ
            rankingView?.deactivate()
            guessView?.deactivate()
            
            // Reset state cho views
            rankingView?.resetState()
            guessView?.resetState()
        }
        
        // Cập nhật giao diện với delay để tránh treo
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self else { return }
            print("yolo Updating active view for filter: \(filter)")
            self.updateActiveView()
        }
    }
}

// MARK: - Ranking Delegate
extension CameraVC: RankingViewDelegate {
    func didSelectRankingCell(at index: Int, image: UIImage?, imageURL: String?) {
        guard let cell = rankingView?.collectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as? RankingCell,
              let image = image,
              let imageURL = imageURL else {
            print("No valid cell, image, or imageURL at index \(index)")
            return
        }
        
        cell.bgImage.image = image
        cell.bgImage.isHidden = false
        cell.animateSelection()
        
        print("Selected ranking cell at index \(index) with image URL: \(imageURL)")
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension CameraVC: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput,
                   didStartRecordingTo fileURL: URL,
                   from connections: [AVCaptureConnection]) {
        print("Started recording to: \(fileURL)")
    }
    
    func fileOutput(_ output: AVCaptureFileOutput,
                   didFinishRecordingTo outputFileURL: URL,
                   from connections: [AVCaptureConnection],
                   error: Error?) {
        if let error = error {
            print("Error recording video: \(error.localizedDescription)")
            return
        }
        
        print("Finished recording to: \(outputFileURL)")
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = documentsDirectory.appendingPathComponent("recordedVideo_\(Date().timeIntervalSince1970).mp4")
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            try FileManager.default.copyItem(at: outputFileURL, to: destinationURL)
            print("Video saved to: \(destinationURL)")
            
            // Navigate to result screen
            let resultVC = ResultVC()
            resultVC.videoURL = destinationURL
            navigationController?.pushViewController(resultVC, animated: false)
        } catch {
            print("Error saving video: \(error.localizedDescription)")
        }
    }
}
