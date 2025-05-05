//
//  VideoVC.swift
//  SurvivalChallenge
//
//  Created by Apple on 16/4/25.
//

import UIKit
import Stevia
import AVKit
import MiTuKit

class ResultVideoVC: UIViewController {
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var saveButton: InnerShadowButton!
    @IBOutlet weak var menuButton: UIButton!
    
    var videoURL: URL?
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupAudio()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let url = videoURL {
            playVideo(into: videoView, url: url)
        } else {
            print("⚠️ videoURL is nil")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.pause()
        player = nil
    }
    
    @IBAction func didTapShareBtn(_ sender: Any) {
        guard let url = videoURL else { return }
        self.share(items: [url])
    }
    
    @IBAction func didTapBackBtn(_ sender: Any) {
        navigationController?.popViewController(animated: false)
    }
    
    @IBAction func didTapMenuBtn(_ sender: Any) {
        setupContextMenu()
    }
}

extension ResultVideoVC {
    private func playVideo(into containerView: UIView, url: URL) {
        let player = AVPlayer(url: url)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        playerViewController.videoGravity = .resizeAspectFill
        playerViewController.showsPlaybackControls = true
        
        self.addChild(playerViewController)
        playerViewController.view.frame = containerView.bounds
        containerView.addSubview(playerViewController.view)
        playerViewController.didMove(toParent: self)
        
        player.play()
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
    
    func setupViews() {
        saveButton.style {
            $0.layoutIfNeeded()
            $0.clipsToBounds = true
            $0.titleLabel?.text = Localized.Video.save
            $0.titleLabel?.font = UIFont.sfProDisplayBold(ofSize: 17)
            $0.shadows = [
                InnerShadow(color: UIColor.white.withAlphaComponent(0.8), offset: CGSize(width: 0, height: 2), blur: 4),
                InnerShadow(color: .hex3853B4, offset: CGSize(width: 0, height: -2), blur: 4)
            ]
            $0.layer.cornerRadius = $0.frame.height / 2
        }
    }
    
    private func setupContextMenu() {
        guard let url = videoURL else { return }
        
        let share = UIAction(title: Localized.MyVideos.share,
                             image: .upload) { [weak self] _ in
            guard let self = self else { return }
            self.share(items: [url])
        }
        
        let delete = UIAction(title: Localized.MyVideos.delete,
                              image: .trashIc,
                              attributes: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.showDeleteConfirmation()
        }
        
        let menu = UIMenu(title: "", children: [share, delete])
        menuButton.showsMenuAsPrimaryAction = true
        menuButton.menu = menu
    }
    
    private func showDeleteConfirmation() {
        guard let url = videoURL else { return }
        
        let alert = UIAlertController(
            title: Localized.MyVideos.deleteYourVideo,
            message: nil,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: Localized.MyVideos.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: Localized.MyVideos.delete, style: .destructive) { [weak self] _ in
            Task {
                let fileName = url.lastPathComponent
                await FileHelper.shared.removeFile(fileName: fileName, from: .record)
                self?.navigationController?.popViewController(animated: false)
            }
        })
        
        present(alert, animated: true)
    }
}
