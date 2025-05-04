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
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var musicView: UIView!
    @IBOutlet weak var musicLabel: UILabel!
    
    @IBOutlet weak var closeMusic: UIButton!
    @IBOutlet weak var filterView: FilterModeView!
    @IBOutlet weak var cameraButton: UIView!
    @IBOutlet weak var discardButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var timeLB: UILabel!
    @IBOutlet weak var musicLabelTrailingToSuperView: NSLayoutConstraint!
    @IBOutlet weak var musicLabelTrailingToCloseMusic: NSLayoutConstraint!
    private var progressView: CircularProgressView!
    
    var coloringView: ColoringView?
    var designType: DesignType?
    var filterType: FilterType?
    var selectedChallenge: SurvivalChallengeEntity?
    var currentChallenge: SurvivalChallengeEntity?
    var music: SurvivalChallengeEntity?
    
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
        setupTapGesture()
        setupCamera()
        setupVideoComposer()
        resetMusicSelection()
        setupHandles()
        setupAudio()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkCameraPermission()
//        resetState()
        
//        if isAccessCamera {
//            if !captureSession.isRunning {
//                DispatchQueue.global().async { [weak self] in
//                    guard let self = self else { return }
//                    startSession()
//                }
//            }
//        }
        
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
            if music != nil {
                audioQueue.async { [weak self] in
                    guard let self = self else { return }
                    audioPlayer?.play()
                }
            }
            accumulatedTime = recordedTime
            
            if let videoComposer = self.videoComposer {
                videoComposer.validateSegments()
                videoComposer.resetComposer()
            }
            
            if isFlashOn {
                if isUsingFrontCamera {
                    originalBrightness = UIScreen.main.brightness
                    UIScreen.main.brightness = 1.0
                } else {
                    turnOnTorch()
                }
            }
        }
        
        updateActiveView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resetAllDetectionState()
        if isAccessCamera {
            if captureSession.isRunning {
                stopSession()
            }
        }
        stopAudio()
        clear()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
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
        
        // Không ẩn/hiện view ở đây, chỉ chuyển đổi camera
        isUsingFrontCamera.toggle()
        
        // Tạm thời ẩn view đang hiển thị
        let activeView = (filterType == .ranking) ? rankingView :
        (filterType == .guess) ? guessView : coloringView
        activeView?.alpha = 0  // Chỉ làm mờ không ẩn hoàn toàn
        
        // Thực hiện chuyển đổi camera
        setUpCaptureSessionInput()
        
        // Sau khi chuyển đổi xong, cập nhật session cho view đang hoạt động
        // (không cần delay)
        switch filterType {
        case .ranking:
            rankingView?.setPreviewSession(captureSession, isUsingFrontCamera)
        case .guess:
            guessView?.setPreviewSession(captureSession, isUsingFrontCamera)
        default:
            break
        }
        
        // Hiển thị view trở lại với animation nhẹ
        UIView.animate(withDuration: 0.2) {
            activeView?.alpha = 1
        }
        
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
    
    @IBAction func didTapCloseMusicBtn(_ sender: Any) {
        hasMusic = false
        music = nil
        updateMusicView()
        audioQueue.async { [weak self] in
            guard let self else { return }
            audioPlayer?.pause()
        }
    }
    
    private func setupVideoComposer() {
        let width = 540
        let height = 960
        videoComposer = VideoComposer(width: width, height: height)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("⚙️ deinit \(Self.self)")
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
        
        if filterType == .ranking {
                rankingView?.stopRecording()
            }
        
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

// MARK: - Audio
extension CameraVC {
    private func setupAudio() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func playAudio(with url: URL, music: SurvivalChallengeEntity) {
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            
            let playerItem = AVPlayerItem(url: url)
            
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(audioDidFinishPlaying),
                                                   name: .AVPlayerItemDidPlayToEndTime,
                                                   object: playerItem)
            
            audioPlayer = AVPlayer(playerItem: playerItem)
            audioPlayer?.play()
            
            DispatchQueue.main.async { [weak self] in
                self?.hasMusic = true
                self?.updateMusicView(music: music)
            }
        }
    }
    
    private func updateMusicView(music: SurvivalChallengeEntity? = nil) {
        if hasMusic {
            musicLabel.text = music?.name
            closeMusic.isHidden = false
            musicLabelTrailingToSuperView.priority = UILayoutPriority(999)
            musicLabelTrailingToCloseMusic.priority = UILayoutPriority(1000)
        } else {
            musicLabel.text = Localized.Camera.addMusic
            closeMusic.isHidden = true
            musicLabelTrailingToSuperView.priority = UILayoutPriority(1000)
            musicLabelTrailingToCloseMusic.priority = UILayoutPriority(999)
        }
    }
    
    @objc private func audioDidFinishPlaying() {
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            self.audioPlayer?.seek(to: .zero)
            self.audioPlayer?.play()
        }
    }
    
    @objc private func stopAudio() {
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            self.audioPlayer?.pause()
            self.audioPlayer = nil
        }
    }
    
    private func getSelectedMusicURL(from music: SurvivalChallengeEntity?) async -> URL? {
        guard let music = music,
              let urlString = music.imageUrlNew.first,
              let remoteURL = URL(string: urlString.url) else { return nil }
        
        let fileName = "\(music.category)_\(remoteURL.lastPathComponent)"
        print("⚙️ File name: \(fileName)")
        let localURL = FileHelper.shared.fileURL(fileName: fileName, in: .audiosCache)
        print("⚙️ Local URL: \(localURL)")
        
        if FileHelper.shared.fileExists(fileName: fileName, in: .audiosCache) {
            print("⚙️ File exists, using local file.")
            return localURL
        }
        
        do {
            try await FileHelper.shared.downloadFile(from: remoteURL, to: localURL)
            print("⚙️ Download done, using selected file.")
            return localURL
        } catch {
            print("⚠️ Download audio failed: \(error)")
            return nil
        }
    }
}

// MARK: - Functions
extension CameraVC {
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
        self.progressView?.isHidden = false
        self.progressView?.alpha = 0
        self.timeLB.isHidden = false
        self.timeLB.alpha = 0
        UIView.animate(withDuration: 0.3, animations: {
            self.flashButton.alpha = 0
            self.filterView.alpha = 0
            self.progressView?.alpha = 1
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
            self.progressView?.alpha = 0
            self.discardButton.alpha = 0
            self.saveButton.alpha = 0
            self.timeLB.alpha = 0
        }, completion: { _ in
            self.progressView?.isHidden = true
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
    
    // MARK: - Start record
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
                rankingView.startRecording()
                videoComposer.setEffectType(filterType, designType: designType, view: rankingView!)
            case .guess:
                videoComposer.setEffectType(filterType, designType: designType, view: guessView!)
            case .coloring:
                videoComposer.setEffectType(filterType, designType: designType, view: coloringView!)
            default:
                break
            }
        }
        
        videoComposer.startRecording()
        recordingState = .recording
        
        DispatchQueue.main.async {
            self.updateUIWhenStartRecord()
            self.progressView?.startProgress(duration: 120)
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
    
    // MARK: - Pause record
    private func pauseRecording() {
        if let startTime = self.startTime {
            accumulatedTime += Date().timeIntervalSince(startTime)
        }
        
        recordingState = .paused
        updateUIWhenPauseRecord()
        
        if filterType == .ranking {
            rankingView?.stopRecording()
        }
        
        videoComposer.pauseRecording()
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Resume record
    private func resumeRecording() {
        videoComposer.resumeRecording()
        
        
        if filterType == .ranking {
            rankingView?.startRecording()
        }
        
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
    
    // MARK: - Stop record
    private func stopRecording() {
        timer?.invalidate()
        timer = nil
        recordingState = .paused
        
        if filterType == .ranking {
            rankingView?.stopRecording()
        }
        
        updateUIWhenPauseRecord()
        if !progressView.isPaused {
            progressView.pauseProgress()
        }
        
        Utils.showIndicator()
        
        videoComposer.finalizeAndExportVideo { [weak self] url in
            Task {
                guard let self = self,
                      let videoUrl = url else {
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        Utils.showAlertOK(title: "Error", message: "Failed to create video")
                        Utils.removeIndicator()
                        
                        progressView.discardLastSegment()
                        videoComposer.clearSegments()
                    }
                    return
                }
                
                Utils.removeIndicator()
                let resultVC = ResultVC()
                let selectedMusicURL = await self.getSelectedMusicURL(from: self.music)
                
                if let audioURL = selectedMusicURL {
                    VideoComposer.mergeAudioWithVideo(videoURL: videoUrl, audioURL: audioURL, completion: { finalUrl in
                        resultVC.videoURL = finalUrl
                    })
                } else {
                    resultVC.videoURL = videoUrl
                }
                self.isInNaviStack = true
                self.navigationController?.pushViewController(resultVC, animated: true)
            }
        }
    }
}

// MARK: - Helper Methods
extension CameraVC {
    private func resetMusicSelection() {
        musicLabel.text = Localized.Camera.addMusic
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
        }
        
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
        
        overlayView.style {
            $0.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            $0.fillContainer()
            $0.isHidden = true
        }
        
        musicLabel.style {
            $0.font = UIFont.sfProDisplayBold(ofSize: 13)
            $0.textColor = .white
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
        coloringView.top(200)
        coloringView.Bottom == filterView.Top - 10
        
        coloringView.isHidden = true
        print("ColoringView initialized")
    }
    
    // MARK: - Update active view
    func updateActiveView() {
        rankingView?.isHidden = true
        guessView?.isHidden = true
        coloringView?.isHidden = true
        
        guard let filterType = filterType else {
            print("No filter type selected.")
            return
        }
        
        switch filterType {
        case .ranking:
            if let designType = designType {
                rankingView?.designType = designType
            }
            if let challenge = currentChallenge {
                rankingView?.setChallenge(challenge)
            }
            
            rankingView?.setPreviewSession(captureSession, isUsingFrontCamera)
            rankingView?.isHidden = false
            rankingView?.activate()
        case .guess:
            if let designType = designType {
                guessView?.designType = designType
            }
            if let challenge = currentChallenge {
                guessView?.setChallenge(challenge)
            }
            guessView?.setPreviewSession(captureSession, isUsingFrontCamera)
            guessView?.isHidden = false
            guessView?.activate()
        case .coloring:
            print("yolo Showing ColoringView")
            coloringView?.isHidden = false
            if let designType = designType {
                coloringView?.designType = designType
            }
            
        default:
            print("No valid filter type.")
        }
        
        view.layoutIfNeeded()
        
        if videoComposer != nil {
            switch filterType {
            case .ranking:
                videoComposer.setEffectType(filterType, designType: designType, view: rankingView!)
            case .guess:
                videoComposer.setEffectType(filterType, designType: designType, view: guessView!)
            case .coloring:
                videoComposer.setEffectType(filterType, designType: designType, view: coloringView!)
            default:
                break
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
        
        let cameraButtonTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapCameraButton(_:)))
        cameraButton.addGestureRecognizer(cameraButtonTapGesture)
        
        let musicViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapMusicView(_:)))
        musicView.addGestureRecognizer(musicViewTapGesture)
    }
    
    @objc func handleTap(_ gesture: UIGestureRecognizer) {
        let location = gesture.location(in: view)
        
        if !musicView.isHidden && !musicView.frame.contains(location) {
            isMusicViewVisible = false
        }
    }
    
    @objc func didTapCameraButton(_ gesture: UITapGestureRecognizer) {
        switch recordingState {
        case .notRecording:
            startRecording()
        case .recording:
            pauseRecording()
        case .paused:
            resumeRecording()
        }
    }
    
    @objc func didTapMusicView(_ gesture: UITapGestureRecognizer) {
        let musicVC = MusicViewController()
        musicVC.delegate = self
        musicVC.presentationController?.delegate = self
        if let sheet = musicVC.sheetPresentationController {
            sheet.detents = Utils.isIpad() ? [.large()] : [.medium()]
            sheet.preferredCornerRadius = 20
            sheet.prefersGrabberVisible = true
        }
        musicVC.modalPresentationStyle = .pageSheet
        self.present(musicVC, animated: true)
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
    }
}

// MARK: - Detect Camera
extension CameraVC: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let currentState = recordingState
        
        if currentState == .recording {
            videoComposer.processSampleBuffer(sampleBuffer)
        }
    }
}

// MARK: - Setup Camera
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
    
    private func updateFlashlightButton() {
        let imageName = isFlashOn ? UIImage.lightningOffIc : UIImage.lightningOnIc
        flashButton.setImage(imageName, for: .normal)
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
        if self.filterType == filter {
            // Chỉ cập nhật properties
            self.designType = designType
            self.currentChallenge = challenge
            
            // Cập nhật thông tin cho view hiện tại mà không làm lại toàn bộ quá trình
            switch filter {
            case .ranking:
                if let designType = designType {
                    rankingView?.designType = designType
                }
                if let challenge = challenge {
                    rankingView?.setChallenge(challenge)
                }
            case .guess:
                if let designType = designType {
                    guessView?.designType = designType
                }
                if let challenge = challenge {
                    guessView?.setChallenge(challenge)
                }
            default:
                break
            }
            
            return
        }
        
        self.filterType = filter
        self.designType = designType
        self.currentChallenge = challenge
        
        updateActiveView()
    }
}

// MARK: - MusicViewControllerDelegate
extension CameraVC: MusicViewControllerDelegate, UIAdaptivePresentationControllerDelegate {
    func didChooseMusic(music: SurvivalChallengeEntity) {
        self.music = music
        
        Task { [weak self] in
            guard let self = self else { return }
            let selectedMusicURL = await self.getSelectedMusicURL(from: music)
            guard let url = selectedMusicURL else {
                print("⚠️ Failed to get music URL")
                return
            }
            
            self.playAudio(with: url, music: music)
        }
    }
}

// MARK: - Ranking Delegate
extension CameraVC: RankingViewDelegate {
    func didStartRecording() {
        startRecording()
    }
    
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
