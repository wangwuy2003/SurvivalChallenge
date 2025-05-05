//
//  PreviewViewController.swift
//  SurvivalChallenge
//
//  Created by Apple on 15/4/25.
//

import UIKit
import MiTuKit
import AVKit
import AVFoundation

//MARK: -Initialization
class PreviewVC: UIViewController {
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var tryNowButton: InnerShadowButton!
    @IBOutlet weak var gradientView: CustomGradientView!
    @IBOutlet weak var previewView: UIView!
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
    private var downloadTask: Task<Void, Never>?
    private var isViewActive = false
    
    var trendItem: SurvivalChallengeEntity?
    var filterType: FilterType?
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("⚙️ deinit \(Self.self)")
    }
}

//MARK: - View Life Cycle
extension PreviewVC {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupHandles()
        setupAudio()
        
        NotificationCenter.default.addObserver(self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )
        NotificationCenter.default.addObserver(self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isViewActive = true
        configurePreview()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        isViewActive = false
        clear()
        downloadTask?.cancel()
        downloadTask = nil
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = previewView.bounds
    }
}

//MARK: - Functions
extension PreviewVC {
    private func setupUI() {
        guard let item = trendItem else { return }
        
        userNameLabel.text = item.username
        descriptionLabel.text = item.textDes
        
        gradientView.startPoint = .topCenter
        gradientView.endPoint = .bottomCenter
        gradientView.colors = [
            .black.withAlphaComponent(0),
            .black.withAlphaComponent(0.25),
        ]
        
        tryNowButton.backgroundColor = .hex4E75FF
        tryNowButton.tintColor = .white
        tryNowButton.layer.cornerRadius = 26
        tryNowButton.setTitle(Localized.DescriptionChallenge.tryNow, for: .normal)
        tryNowButton.shadows = [
            InnerShadow(color: UIColor.white.withAlphaComponent(0.25), offset: CGSize(width: 0, height: 2), blur: 4),
            InnerShadow(color: .hex3853B4, offset: CGSize(width: 0, height: -2), blur: 4)
        ]
    }
    
    private func setupHandles() {
        backButton.handle { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        
        tryNowButton.handle { [weak self] in
            guard let self = self else {return}
            let cameraVC = CameraVC()
            
            switch trendItem?.category {
            case "ranking":
                cameraVC.filterType = .ranking
            case "guess":
                cameraVC.filterType = .guess
            case "coloring":
                cameraVC.filterType = .coloring
            default:
                break
            }
            
            cameraVC.currentChallenge = trendItem
            
            let transition = CATransition()
            transition.duration = 0.3
            transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            transition.type = .fade
            self.navigationController?.view.layer.add(transition, forKey: kCATransition)
            
            self.navigationController?.pushViewController(cameraVC, animated: false)
        }
    }
    
    private func clear() {
        player?.pause()
        
        if let playerItem = player?.currentItem {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        }
        
        playerLayer?.removeFromSuperlayer()
        
        playerLayer = nil
        player = nil
    }
    
    private func configurePreview() {
            downloadTask?.cancel()
            
            downloadTask = Task { [weak self] in
                guard let self = self,
                      let item = trendItem,
                      let video = item.imageUrlNew.first,
                      let videoURL = URL(string: video.url) else { return }

                let fileName = "\(item.category)_\(videoURL.lastPathComponent)"
                print("⚙️ fileName: \(fileName)")
                let localURL = FileHelper.shared.fileURL(fileName: fileName, in: .videosCache)
                print("⚙️ localURL: \(localURL)")
                
                guard self.isViewActive else { return }
                
                if FileHelper.shared.fileExists(fileName: fileName, in: .videosCache) {
                    print("⚙️ File exists, playing local file.")
                    self.playVideo(in: self.previewView, with: localURL)
                } else {
                    do {
                        print("⚙️ Downloading video...")
                        try await FileHelper.shared.downloadFile(from: videoURL, to: localURL)
                        
                        guard self.isViewActive else { return }
                        
                        self.playVideo(in: self.previewView, with: localURL)
                    } catch {
                        print("⚠️ Failed to download video: \(error)")
                        
                        guard self.isViewActive else { return }
                        
                        self.playVideo(in: self.previewView, with: videoURL)
                    }
                }
            }
        }
    
    private func setupAudio() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func playVideo(in view: UIView, with url: URL) {
        player = AVPlayer(url: url)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = view.bounds
        playerLayer?.videoGravity = .resizeAspectFill
        
        if let playerLayer = playerLayer {
            view.layer.addSublayer(playerLayer)
        }
        
        player?.play()
    }
    
    @objc private func playerDidFinishPlaying() {
        player?.seek(to: .zero)
        player?.play()
    }
    
    @objc private func appWillEnterForeground() {
        player?.play()
    }
    
    @objc private func appDidEnterBackground() {
        player?.pause()
    }
}
