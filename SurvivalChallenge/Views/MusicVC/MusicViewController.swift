//
//  MusicViewController.swift
//  EyeTrendFilter
//
//  Created by Hồ Hữu Nhân on 15/4/25.
//

import UIKit
import AVFoundation
internal import Alamofire
import MiTuKit

protocol MusicViewControllerDelegate: AnyObject {
    func didChooseMusic(music: SurvivalChallengeEntity)
}

class MusicViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    private var audioPlayer: AVPlayer?
    weak var delegate: MusicViewControllerDelegate?
    private let musicList: [SurvivalChallengeEntity] = HomeViewModel.shared.audioItems
    private var currentPlayingIndex: IndexPath?
    private var currentDownloadingIndex: IndexPath?
    
    private let audioQueue = DispatchQueue(label: "com.survival.audioQueue")
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("⚙️ deinit \(Self.self)")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupAudio()
        
        tableView.register(UINib(nibName: "MusicTableViewCell", bundle: nil), forCellReuseIdentifier: "musicCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        
        titleLabel.text = Localized.Camera.addMusic
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        audioQueue.async { [weak self] in
            self?.audioPlayer?.pause()
            self?.audioPlayer = nil
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
    
    private func playAudio(with url: URL, indexPath: IndexPath) {
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
            
            Queue.main { [weak self] in
                self?.currentPlayingIndex = indexPath
            }
        }
    }
    
    private func pauseAudio() {
        audioQueue.async { [weak self] in
            self?.audioPlayer?.pause()
        }
    }
    
    @objc private func audioDidFinishPlaying() {
        if let indexPath = currentPlayingIndex {
            currentPlayingIndex = nil
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
    
    func getSelectedMusicURL(from music: SurvivalChallengeEntity?) async -> URL? {
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

// MARK: - TableViewDelegate
extension MusicViewController: UITableViewDelegate, UITableViewDataSource {
 
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return musicList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "musicCell", for: indexPath) as! MusicTableViewCell
        cell.selectionStyle = .none
        cell.configCell(model: musicList[indexPath.row], isPlaying: indexPath == currentPlayingIndex)
        cell.delegate = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = musicList[indexPath.row]
        
        self.dismiss(animated: true) { [weak self] in
            self?.delegate?.didChooseMusic(music: selectedItem)
        }
    }
}

// MARK: - MusicTableViewCellDelegate
extension MusicViewController: MusicTableViewCellDelegate {
    func didTapPauseButton() {
        pauseAudio()
        
        if let indexPath = currentPlayingIndex {
            currentPlayingIndex = nil
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }

    func didTapPlayButton(in cell: MusicTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        print("🎵 Button tapped at: \(indexPath.row)")
        NotificationCenter.default.post(name: .didPlayMusic, object: nil)

        var indexPathsToReload: [IndexPath] = []

        if let current = currentPlayingIndex, current != indexPath {
            pauseAudio()
            indexPathsToReload.append(current)
        }

        let selectedItem = musicList[indexPath.row]

        guard let urlString = selectedItem.imageUrlNew.first, let remoteURL = URL(string: urlString.url) else {
            print("⚠️ Invalid URL")
            return
        }

        let fileName = "\(selectedItem.category)_\(remoteURL.lastPathComponent)"
        print("⚙️ File name: \(fileName)")
        let localURL = FileHelper.shared.fileURL(fileName: fileName, in: .audiosCache)
        print("⚙️ Local URL: \(localURL)")

        currentPlayingIndex = indexPath
        currentDownloadingIndex = indexPath
        indexPathsToReload.append(indexPath)
        tableView.reloadRows(at: indexPathsToReload, with: .none)

        if FileHelper.shared.fileExists(fileName: fileName, in: .audiosCache) {
            print("⚙️ File exists, playing local file.")
            playAudio(with: localURL, indexPath: indexPath)
        } else {
            Task {
                do {
                    print("⚙️ Downloading file...")
                    try await FileHelper.shared.downloadFile(from: remoteURL, to: localURL)

                    if self.currentDownloadingIndex == indexPath {
                        print("⚙️ Download done, playing selected file.")
                        self.playAudio(with: localURL, indexPath: indexPath)
                    } else {
                        print("⚙️ Download done, but not playing selected file.")
                    }
                } catch {
                    print("⚠️ Failed to download audio: \(error)")
                }
            }
        }
    }
}
