//
//  ResultVC.swift
//  SurvivalChallenge
//
//  Created by Apple on 28/4/25.
//

import UIKit
import AVKit

class ResultVC: UIViewController {

    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var shareButton: InnerShadowButton!
    @IBOutlet weak var saveButton: InnerShadowButton!
    
    var videoURL: URL?
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = videoView.bounds
    }
    
    @IBAction func didTapShareBtn(_ sender: Any) {
    }
    
    @IBAction func didTapSaveBtn(_ sender: Any) {
        Task { [weak self] in
            guard let self = self,
                  let url = self.videoURL else { return }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd_HHmmss"
            let fileName = "Result_\(formatter.string(from: Date())).mp4"
            
            let success = await FileHelper.shared.saveVideoToRecordFolder(from: url, fileName: fileName)
            
            let title = success ? Localized.Result.success : Localized.Result.error
            let message = success ? Localized.Result.videoSavedSuccessfully : Localized.Result.videoSavedError
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                if success {
                    NotificationCenter.default.post(name: .didSaveVideo, object: nil)
                }
            }
            alert.addAction(okAction)
            self.present(alert, animated: true)
        }
    }
    
    @IBAction func didTapBackBtn(_ sender: Any) {
        let alert = UIAlertController(
            title: Localized.Result.discardYourVideo,
            message: "",
            preferredStyle: .alert)
        let cancelAction = UIAlertAction(
            title: Localized.Result.cancel,
            style: .cancel)
        let okAction = UIAlertAction(
            title: Localized.Result.discard,
            style: .destructive) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        
        self.present(alert, animated: true)
    }
    
    @IBAction func didTapHomeBtn(_ sender: Any) {
        let alert = UIAlertController(
            title: Localized.Result.discardYourVideo,
            message: "",
            preferredStyle: .alert)
        let cancelAction = UIAlertAction(
            title: Localized.Result.cancel,
            style: .cancel)
        let okAction = UIAlertAction(
            title: Localized.Result.discard,
            style: .destructive) { [weak self] _ in
                NotificationCenter.default.post(name: .didReturnToHomeFromResult, object: nil)
                self?.navigationController?.popToRootViewController(animated: false)
        }
        
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        
        self.present(alert, animated: true)
    }
    
    private func setupViews() {
        shareButton.setTitleColor(.hex212121, for: .normal)
        shareButton.backgroundColor = .hexFFA1A1
        shareButton.layer.cornerRadius = 26
        shareButton.shadows = [
            InnerShadow(color: UIColor.white.withAlphaComponent(0.25), offset: CGSize(width: 0, height: 2), blur: 4),
            InnerShadow(color:UIColor.black.withAlphaComponent(0.25), offset: CGSize(width: 0, height: -2), blur: 4)
        ]
        
        saveButton.backgroundColor = .hex4E75FF
        saveButton.layer.cornerRadius = 26
        saveButton.shadows = [
            InnerShadow(color: UIColor.white.withAlphaComponent(0.25), offset: CGSize(width: 0, height: 2), blur: 4),
            InnerShadow(color: UIColor.hex3853B4, offset: CGSize(width: 0, height: -2), blur: 4)
        ]
        saveButton.setTitleColor(.white, for: .normal)
        
        shareButton.setTitle(Localized.Result.share, for: .normal)
        saveButton.setTitle(Localized.Result.save, for: .normal)
    }
    
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        player?.pause()
        player = nil
    }
}
