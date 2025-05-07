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

//MARK: -Initialization
class CameraVC: UIViewController {
    //MARK: - Outlets
    @IBOutlet weak var rankingView: RankingView!
    @IBOutlet weak var guessView: GuessView!
    @IBOutlet weak var lightningButton: UIButton!
    @IBOutlet weak var swapCamera: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var magicButtonn: UIButton!
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
    
    //MARK: - Properties
    var coloringView: ColoringView?
    var designType: DesignType?
    var filterType: FilterType?
    var currentChallenge: SurvivalChallengeEntity?
    var music: SurvivalChallengeEntity?
    
    private lazy var overlayView = UIView()
    var isAccessCamera: Bool = false
    var challenges: [SurvivalChallengeEntity] = HomeViewModel.shared.allChallenges
    
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("⚙️ yolo deinit \(Self.self)")
    }
}

//MARK: - View Life Cycle
extension CameraVC {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupAudio()
        setupCamera()
        setupUI()
        setupVideoComposer()
        setupHandles()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(resetCompleteState),
                                               name: .didReturnToHomeFromResult,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(stopAudio), name: .didPlayMusic, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isInNaviStack && !isPop {
            if filterType == .guess {
                guessView.restoreCachedImages()
            } else if filterType == .ranking {
                rankingView.restoreCachedImages()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkCameraPermission()
        if let currentChallenge = currentChallenge {
            if let index = challenges.firstIndex(where: { $0.id == currentChallenge.id }) {
                filterView.scrollToItem(at: index)
            } else {
                filterView.scrollToItem(at: 0)
            }
        } else {
            filterView.scrollToItem(at: 0)
        }
        
        if isInNaviStack && !isPop {
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
            if music != nil {
                Task { [weak self] in
                    guard let self = self else { return }
                    let selectedMusicURL = await self.getSelectedMusicURL(from: self.music)
                    guard let url = selectedMusicURL else {
                        print("⚠️ Failed to restore music URL")
                        return
                    }
                    audioQueue.async { [weak self] in
                        guard let self = self else { return }
                        if self.audioPlayer == nil {
                            let playerItem = AVPlayerItem(url: url)
                            self.audioPlayer = AVPlayer(playerItem: playerItem)
                            NotificationCenter.default.addObserver(self,
                                                                   selector: #selector(audioDidFinishPlaying),
                                                                   name: .AVPlayerItemDidPlayToEndTime,
                                                                   object: playerItem)
                            print("⚙️ Reinitialized audioPlayer")
                        }
                        if self.recordingState == .recording {
                            self.audioPlayer?.play()
                            print("⚙️ Music playing on viewDidAppear")
                        } else {
                            self.audioPlayer?.pause()
                            print("⚙️ Music paused on viewDidAppear")
                        }
                    }
                }
            }
        }
        updateActiveView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAudio()
        stopSession()
        
        if isPop {
            resetAllDetectionState()
            resetCompleteState()
            clear()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    @objc private func resetCompleteState() {
        recordingState = .notRecording
        progressView?.isHidden = true
        progressView?.discardAllSegment()
        timer?.invalidate()
        timer = nil
        recordedTime = 0
        accumulatedTime = 0
        videoComposer?.clearSegments()
        updateUIWhenResetRecord()
        resetMusicSelection()
        
        guessView.shouldKeepImagesOnReset = false
        rankingView.shouldKeepImagesOnReset = false
    
        resetAllDetectionState()
        isInNaviStack = false
        isPop = false
    }
}

//MARK: - Functions
extension CameraVC {
    private func setupUI() {
        rankingView.delegate = self
        filterView.delegate = self
        
        setupColoringView()
        
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
        
        view.subviews {
            overlayView
        }
        
        overlayView.style {
            $0.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            $0.fillContainer()
            $0.isHidden = true
        }
        
        musicLabel.style {
            $0.font = UIFont.sfProDisplayBold(ofSize: 13)
            $0.textColor = .white
            $0.text = Localized.Camera.addMusic
        }
        
        cameraButton.style {
            $0.backgroundColor = .clear
            $0.layer.borderColor = UIColor.white.cgColor
            $0.layer.borderWidth = 5.0
            $0.layer.cornerRadius = 40
            $0.isUserInteractionEnabled = true
        }
    }
    
    private func setupColoringView() {
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
    
    private func setupHandles() {
        progressView.onCompletion = { [weak self] in
            guard let self = self else { return }
            
            print("⚙️ Done recording")
            self.pauseRecording()
            self.recordingState = .notRecording
            self.updateUIWhenPauseRecord()
        }
        
        progressView.onPause = { [weak self] isPaused in
            guard let self = self else { return }
            if isPaused {
                pauseRecording()
            } else {
                resumeRecording()
            }
        }
        
        progressView.onReset = { [weak self] in
            guard let self = self else { return }
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
        
        musicView.tapHandle { [weak self] in
            guard let self = self else { return }
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
    }
    
    private func clear() {
        turnOffTorch()
        if isPop {
            timer?.invalidate()
            timer = nil
            videoComposer = nil
            rankingView = nil
            guessView = nil
            coloringView = nil
            audioPlayer = nil
            progressView = nil
        }
    }
    
    private func setupVideoComposer() {
        if videoComposer == nil {
            let width = view.screenWidth
            let height = view.screenHeight
            videoComposer = VideoComposer(width: Int(width), height: Int(height))}
    }
    
    private func resetAllDetectionState() {
        rankingView?.resetState()
        guessView?.resetState()
    }
}

//MARK: - UI Updates
extension CameraVC {
    private func updateActiveView() {
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
                videoComposer.setEffectType(filterType, designType: designType, view: rankingView)
            case .guess:
                videoComposer.setEffectType(filterType, designType: designType, view: guessView)
            case .coloring:
                videoComposer.setEffectType(filterType, designType: designType, view: coloringView!)
            default:
                break
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
            self.backButton.alpha = 0
            self.musicView.alpha = 0
            self.swapCamera.alpha = 0
            self.lightningButton.alpha = 0
            self.magicButtonn.alpha = 0
            self.progressView?.alpha = 1
            self.timeLB.alpha = 1
        }, completion: { _ in
            self.flashButton.isHidden = true
            self.filterView.isHidden = true
            self.backButton.isHidden = true
            self.musicView.isHidden = true
            self.swapCamera.isHidden = true
            self.lightningButton.isHidden = true
            self.magicButtonn.isHidden = true
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
        self.backButton.isHidden = false
        self.backButton.alpha = 0
        self.swapCamera.isHidden = false
        self.swapCamera.alpha = 0
        self.lightningButton.isHidden = false
        self.lightningButton.alpha = 0
        UIView.animate(withDuration: 0.3, animations: {
            self.flashButton.alpha = 1
            self.discardButton.alpha = 1
            self.backButton.alpha = 1
            self.swapCamera.alpha = 1
            self.lightningButton.alpha = 1
        })
    }
    
    private func updateUIWhenResumeRecord() {
        UIView.animate(withDuration: 0.3, animations: {
            self.flashButton.alpha = 0
            self.discardButton.alpha = 0
            self.backButton.alpha = 0
            self.swapCamera.alpha = 0
            self.lightningButton.alpha = 0
        }, completion: { _ in
            self.flashButton.isHidden = true
            self.discardButton.isHidden = true
            self.backButton.isHidden = true
            self.swapCamera.isHidden = true
            self.lightningButton.isHidden = true
        })
    }
    
    private func updateUIWhenResetRecord() {
        self.flashButton.isHidden = false
        self.filterView.isHidden = false
        self.backButton.isHidden = false
        self.musicView.isHidden = false
        self.swapCamera.isHidden = false
        self.lightningButton.isHidden = false
        self.magicButtonn.isHidden = false
        
        UIView.animate(withDuration: 0.3, animations: {
            self.flashButton.alpha = 1
            self.filterView.alpha = 1
            self.backButton.alpha = 1
            self.musicView.alpha = 1
            self.swapCamera.alpha = 1
            self.lightningButton.alpha = 1
            self.magicButtonn.alpha = 1
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
    
    private func updateFlashlightButton() {
        let imageName = isFlashOn ? UIImage.lightningOffIc : UIImage.lightningOnIc
        flashButton.setImage(imageName, for: .normal)
    }
}

//MARK: - Recording
extension CameraVC {
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
                videoComposer.setEffectType(filterType, designType: designType, view: rankingView)
                rankingView.startRecording()
            case .guess:
                videoComposer.setEffectType(filterType, designType: designType, view: guessView)
                guessView.startRecording()
            case .coloring:
                if let coloringView = coloringView {
                    videoComposer.setEffectType(filterType, designType: designType, view: coloringView)
                }
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
            guard let self = self, self.recordingState == .recording,
                  let startTime = self.startTime else { return }
            
            let currentSegmentTime = Date().timeIntervalSince(startTime)
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
        
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            self.audioPlayer?.pause()
        }
    }
    
    private func resumeRecording() {
        videoComposer.resumeRecording()
        startTime = Date()
        recordingState = .recording
        updateUIWhenResumeRecord()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.recordingState == .recording,
                  let startTime = self.startTime else { return }
            let currentSegmentTime = Date().timeIntervalSince(startTime)
            self.recordedTime = self.accumulatedTime + currentSegmentTime
            self.updateTimeLabel()
        }
        
        rankingView.startRecording()
        
        if music != nil {
            Task { [weak self] in
                guard let self = self else { return }
                let selectedMusicURL = await self.getSelectedMusicURL(from: self.music)
                guard let url = selectedMusicURL else {
                    print("⚠️ Failed to get music URL in resumeRecording")
                    return
                }
                audioQueue.async { [weak self] in
                    guard let self = self else { return }
                    if self.audioPlayer == nil {
                        let playerItem = AVPlayerItem(url: url)
                        self.audioPlayer = AVPlayer(playerItem: playerItem)
                        NotificationCenter.default.addObserver(self,
                                                               selector: #selector(audioDidFinishPlaying),
                                                               name: .AVPlayerItemDidPlayToEndTime,
                                                               object: playerItem)
                        print("⚙️ Reinitialized audioPlayer in resumeRecording")
                    }
                    // Seek to accumulatedTime for synchronization
                    let time = CMTime(seconds: self.accumulatedTime, preferredTimescale: 600)
                    self.audioPlayer?.seek(to: time)
                    self.audioPlayer?.play()
                    print("⚙️ Music resumed at \(self.accumulatedTime) seconds")
                }
            }
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
                guard let self = self,
                      let videoUrl = url else {
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        Utils.showAlertOK(title: "Error", message: "Failed to create video")
                        Utils.removeIndicator()
                        progressView.discardAllSegment()
                        videoComposer.clearSegments()
                    }
                    return
                }
                Utils.removeIndicator()
                let resultVC = ResultVC()
                
                if self.filterType == .guess {
                    self.guessView.shouldKeepImagesOnReset = true
                }
                
                if self.filterType == .ranking {
                    self.rankingView.shouldKeepImagesOnReset = true
                }
                
                
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

//MARK: - Audio
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
    
    private func resetMusicSelection() {
        musicLabel.text = Localized.Camera.addMusic
        music = nil
        hasMusic = false
        stopAudio()
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

//MARK: - Camera
extension CameraVC: AVCaptureVideoDataOutputSampleBufferDelegate {
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
    
    private func setUpCaptureSessionInput() {
        sessionQueue.async {
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.isUsingFrontCamera ? .front : .back) else {
                print("💀Failed to get capture device for camera position: \(self.isUsingFrontCamera ? "front" : "back")")
                return
            }
            do {
                self.captureSession.beginConfiguration()
                
                if let currentInputs = self.captureSession.inputs as? [AVCaptureDeviceInput] {
                    for input in currentInputs {
                        self.captureSession.removeInput(input)
                    }
                }
                
                let input = try AVCaptureDeviceInput(device: device)
                
                if self.captureSession.canAddInput(input) {
                    self.captureSession.addInput(input)
                }
                
                self.captureSession.commitConfiguration()
                
            } catch {
                print("Failed to create capture device input: \(error.localizedDescription)")
            }
        }
    }
    
    private func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.captureSession.startRunning()
            
            if !self.isInNaviStack {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    guard let self = self else { return }
                    self.updateActiveView()
                }
            }
        }
    }
    
    private func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
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
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if recordingState == .recording {
            videoComposer.processSampleBuffer(sampleBuffer)
        }
    }
}

//MARK: - Action Handlers
extension CameraVC {
    @IBAction func didTapBackBtn(_ sender: Any) {
        guessView.shouldKeepImagesOnReset = false
        rankingView.shouldKeepImagesOnReset = false
        hasMusic = false
        music = nil
        stopAudio()
        updateMusicView()
        isPop = true
        
        navigationController?.popViewController(animated: false)
    }
    
    @IBAction func didTapChangeCameraBtn(_ sender: Any) {
        let wasRecording = recordingState == .recording
        if wasRecording {
            pauseRecording()
        }
        
        // Toggle camera
        isUsingFrontCamera.toggle()
        
        // Temporarily hide active view
        let activeView = (filterType == .ranking) ? rankingView :
        (filterType == .guess) ? guessView : coloringView
        activeView?.alpha = 0
        
        // Switch camera
        setUpCaptureSessionInput()
        
        // Update session for active view
        switch filterType {
        case .ranking:
            rankingView?.setPreviewSession(captureSession, isUsingFrontCamera)
        case .guess:
            guessView?.setPreviewSession(captureSession, isUsingFrontCamera)
        default:
            break
        }
        
        // Show view again with animation
        UIView.animate(withDuration: 0.2) {
            activeView?.alpha = 1
        }
        
        // Resume recording if needed
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
            self.progressView.discardAllSegment()
            self.videoComposer.clearSegments()
            
            switch self.filterType {
            case .ranking:
                self.rankingView.shouldKeepImagesOnReset = false
                self.rankingView.resetState()
            case .guess:
                self.guessView.shouldKeepImagesOnReset = false
                self.guessView.resetState()
            default:
                break
            }
            
            self.updateActiveView()
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
}

//MARK: - FilterMode
extension CameraVC: FilterModeDelegate {
    func selectedFocusItem() {
        startRecording()
    }
    
    func getSelectedFocusItem(filter: FilterType, designType: DesignType?, challenge: SurvivalChallengeEntity?) {
        // First check if we're changing filter types
        let isChangingFilterType = self.filterType != filter
        
        // Store the new values
        self.designType = designType
        self.currentChallenge = challenge
        
        if isChangingFilterType {
            switch self.filterType {
            case .ranking:
                self.rankingView.resetState()
            case .guess:
                self.guessView.resetState()
            default:
                break
            }
            
            // Add a fade transition when changing filter types
            UIView.animate(withDuration: 0.3, animations: {
                // Fade out current view
                switch self.filterType {
                case .ranking:
                    self.rankingView?.alpha = 0
                case .guess:
                    self.guessView?.alpha = 0
                case .coloring:
                    self.coloringView?.alpha = 0
                default:
                    break
                }
            }, completion: { _ in
                // Update filter type after fade out
                self.filterType = filter
                
                // Hide all views
                self.rankingView?.isHidden = true
                self.guessView?.isHidden = true
                self.coloringView?.isHidden = true
                
                // Prepare the new view
                switch filter {
                case .ranking:
                    if let designType = designType {
                        self.rankingView?.designType = designType
                    }
                    if let challenge = challenge {
                        self.rankingView?.setChallenge(challenge)
                    }
                    self.rankingView?.setPreviewSession(self.captureSession, self.isUsingFrontCamera)
                    self.rankingView?.isHidden = false
                    self.rankingView?.alpha = 0
                case .guess:
                    if let designType = designType {
                        self.guessView?.designType = designType
                    }
                    if let challenge = challenge {
                        self.guessView?.setChallenge(challenge)
                    }
                    self.guessView?.setPreviewSession(self.captureSession, self.isUsingFrontCamera)
                    self.guessView?.isHidden = false
                    self.guessView?.alpha = 0
                case .coloring:
                    if let designType = designType {
                        self.coloringView?.designType = designType
                    }
                    self.coloringView?.isHidden = false
                    self.coloringView?.alpha = 0
                default:
                    break
                }
                
                // Force layout update
                self.view.layoutIfNeeded()
                
                // Fade in the new view
                UIView.animate(withDuration: 0.3, animations: {
                    switch filter {
                    case .ranking:
                        self.rankingView?.alpha = 1
                    case .guess:
                        self.guessView?.alpha = 1
                    case .coloring:
                        self.coloringView?.alpha = 1
                    default:
                        break
                    }
                }, completion: { _ in
                    // Activate after animation completes
                    switch filter {
                    case .ranking:
                        self.rankingView?.activate()
                    case .guess:
                        self.guessView?.activate()
                    default:
                        break
                    }
                    
                    // Set effect type
                    if self.videoComposer != nil {
                        switch filter {
                        case .ranking:
                            self.videoComposer.setEffectType(filter, designType: self.designType, view: self.rankingView)
                        case .guess:
                            self.videoComposer.setEffectType(filter, designType: self.designType, view: self.guessView)
                        case .coloring:
                            if let coloringView = self.coloringView {
                                self.videoComposer.setEffectType(filter, designType: self.designType, view: coloringView)
                            }
                        default:
                            break
                        }
                    }
                })
            })
        } else {
            // Just update current view if filter type isn't changing
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
            case .coloring:
                if let designType = designType {
                    coloringView?.designType = designType
                }
            default:
                break
            }
            
            // Set effect type
            if videoComposer != nil {
                switch filter {
                case .ranking:
                    videoComposer.setEffectType(filter, designType: self.designType, view: rankingView)
                case .guess:
                    videoComposer.setEffectType(filter, designType: self.designType, view: guessView)
                case .coloring:
                    if let coloringView = coloringView {
                        videoComposer.setEffectType(filter, designType: self.designType, view: coloringView)
                    }
                default:
                    break
                }
            }
        }
    }
}

//MARK: - MusicViewControllerDelegate
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
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        if let music = self.music {
            self.didChooseMusic(music: music)
        }
    }
}

//MARK: - Ranking Delegate
extension CameraVC: RankingViewDelegate {
    func didStartRecording() {
        // Only start recording if not already recording
        if recordingState == .notRecording {
            startRecording()
        }
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

//MARK: - SelectFilterDelegate
extension CameraVC: SelectFilterDelegate {
    func didSelectFilter(challenge: SurvivalChallengeEntity) {
        self.currentChallenge = challenge
        
        if let index = challenges.firstIndex(where: { $0.id == challenge.id }) {
            print("Selected challenge at index: \(index), name: \(challenge.name)")
            filterView.scrollToItem(at: index)
        }
    }
}
