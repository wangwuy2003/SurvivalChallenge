//
//  ResultVC.swift
//  SurvivalChallenge
//
//  Created by Apple on 28/4/25.
//

import UIKit
import AVFoundation

class ResultVC: UIViewController {

    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    var videoURL: URL?
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupVideoPlayer()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = videoView.bounds
    }
    
    @IBAction func didTapBackBtn(_ sender: Any) {
        navigationController?.popViewController(animated: false)
    }
    
    @IBAction func didTapHomeBtn(_ sender: Any) {
        navigationController?.setViewControllers([ContainerVC()], animated: false)
    }
    
    private func setupVideoPlayer() {
        guard let videoURL = videoURL else { return }
        
        // Create AVPlayer
        player = AVPlayer(url: videoURL)
        
        // Create AVPlayerLayer
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = videoView.bounds
        playerLayer?.videoGravity = .resizeAspect
        
        // Add to videoView
        if let playerLayer = playerLayer {
            videoView.layer.addSublayer(playerLayer)
        }
        
        // Start playback
        player?.play()
        
        // Loop the video
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                               object: player?.currentItem,
                                               queue: .main) { [weak self] _ in
            self?.player?.seek(to: CMTime.zero)
            self?.player?.play()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        player?.pause()
        player = nil
    }
}
