//
//  MusicView.swift
//  SurvivalChallenge
//
//  Created by Apple on 17/4/25.
//

import UIKit
import AVFoundation
import Stevia

protocol MusicViewDelegate: AnyObject {
    func didSelectMusic(title: String)
}

class MusicView: UIView {
    weak var delegate: MusicViewDelegate?
    private lazy var grayView = UIView()
    private lazy var titleLB = UILabel()
    private lazy var tableView = UITableView()
    
    private var currentPlayingIndex: IndexPath?
    private var audioItems: [SurvivalChallengeEntity] = []
    private var audioPlayer: AVPlayer?
    private var playerObserver: Any?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        styleView()
        constraint()
        setupTableView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        grayView.layer.cornerRadius = grayView.frame.height / 2
    }
    
    func setAudioItems(_ items: [SurvivalChallengeEntity]) {
        audioItems = items
        tableView.reloadData()
    }
    
    private func playAudio(at indexPath: IndexPath) {
        let audioItem = audioItems[indexPath.row]
        guard let urlString = audioItem.imageUrl.first, let url = URL(string: urlString) else {
            print("Invalid audio URL: \(audioItem.imageUrl.first ?? "none")")
            return
        }
        
        stopAudio()
        
        audioPlayer = AVPlayer(url: url)
        audioPlayer?.play()
        print("Playing: \(audioItem.name)")
        
        delegate?.didSelectMusic(title: audioItem.name)
        
        playerObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: audioPlayer?.currentItem,
            queue: .main
        ) { [weak self] _ in
            self?.audioPlaybackFinished()
        }
    }
    
    func stopAudio() {
        audioPlayer?.pause()
        audioPlayer = nil
        
        if let observer = playerObserver {
            NotificationCenter.default.removeObserver(observer)
            playerObserver = nil
        }
    }
    
    private func audioPlaybackFinished() {
        print("Playback finished")
        stopAudio()
        currentPlayingIndex = nil
        tableView.reloadData()
    }
    
    func resetPlaybackState() {
        currentPlayingIndex = nil
        tableView.reloadData()
    }
}

extension MusicView {
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MusicCell.self)
        tableView.separatorStyle = .none
    }
    
    func setupView() {
        subviews {
            grayView
            titleLB
            tableView
        }
    }
    
    func styleView() {
        grayView.style {
            $0.backgroundColor = .hexA5A5A5
            $0.clipsToBounds = true
        }
        
        titleLB.style {
            $0.text = Localized.Camera.addMusic
            $0.font = UIFont.sfProDisplayBold(ofSize: 17)
            $0.textColor = .hex212121
        }
    }
    
    func constraint() {
        grayView
            .width(36)
            .height(5)
            .top(8)
            .centerHorizontally()
        
        titleLB
            .centerHorizontally()
            .Top == grayView.Bottom + 12
        
        tableView
            .left(0)
            .right(0)
            .bottom(0)
            .Top == titleLB.Bottom + 0
    }
}

// MARK: - TableView Delegate, Datasource
extension MusicView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return audioItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: MusicCell = tableView.dequeueReuseableCell(for: indexPath)
        let audioItem = audioItems[indexPath.row]
        
        cell.configure(with: audioItem)
        cell.isPlaying = (indexPath == currentPlayingIndex)
        cell.onPlayPauseTapped = { [weak self] in
            guard let self else {
                return
            }
            
            if self.currentPlayingIndex == indexPath {
                self.stopAudio()
                self.currentPlayingIndex = nil
            } else {
                self.playAudio(at: indexPath)
                self.currentPlayingIndex = indexPath
            }
            
            tableView.reloadData()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let audioItem = audioItems[indexPath.row]
        print("Selected music: \(audioItem.name)")
    }
}

extension MusicView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}
