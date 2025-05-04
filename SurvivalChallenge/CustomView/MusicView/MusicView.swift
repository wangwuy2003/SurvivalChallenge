////
////  MusicView.swift
////  SurvivalChallenge
////
////  Created by Apple on 17/4/25.
////
//
//import UIKit
//import AVFoundation
//import Stevia
//
//protocol MusicViewDelegate: AnyObject {
//    func didSelectMusic(music: SurvivalChallengeEntity)
//}
//
//class MusicView: UIView {
//    weak var delegate: MusicViewDelegate?
//    private lazy var grayView = UIView()
//    private lazy var titleLB = UILabel()
//    private lazy var tableView = UITableView()
//    
//    private var currentPlayingIndex: IndexPath?
//    private var audioItems: [SurvivalChallengeEntity] = HomeViewModel.shared.audioItems
//    private var audioPlayer: AVPlayer?
//    private var playerObserver: Any?
//    
//    private let audioQueue = DispatchQueue(label: "com.survival.audioQueue", qos: .userInitiated)
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupView()
//        styleView()
//        constraint()
//        setupTableView()
//        setupAudioSession()
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        grayView.layer.cornerRadius = grayView.frame.height / 2
//    }
//    
//    private func setupAudioSession() {
//        do {
//            let audioSession = AVAudioSession.sharedInstance()
//            try audioSession.setCategory(.playback, mode: .default)
//            try audioSession.setActive(true)
//        } catch {
//            print("Failed to set up audio session: \(error)")
//        }
//    }
//    
//    func setAudioItems(_ items: [SurvivalChallengeEntity]) {
//        audioItems = items
//        tableView.reloadData()
//    }
//    
//    private func playAudio(with url: URL, indexPath: IndexPath) {
//        audioQueue.async { [weak self] in
//            guard let self = self else { return }
//            let playerItem = AVPlayerItem(url: url)
//            
//            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
//            NotificationCenter.default.addObserver(self,
//                                                   selector: #selector(audioDidFinishPlaying),
//                                                   name: .AVPlayerItemDidPlayToEndTime,
//                                                   object: playerItem)
//            
//            audioPlayer = AVPlayer(playerItem: playerItem)
//            audioPlayer?.play()
//            
//            DispatchQueue.main.async { [weak self] in
//                self?.currentPlayingIndex = indexPath
//            }
//        }
//    }
//    
//    func stopAudio() {
//        audioQueue.async { [weak self] in
//            guard let self = self else { return }
//            
//            self.audioPlayer?.pause()
//            self.audioPlayer = nil
//            
//            DispatchQueue.main.async {
//                if let observer = self.playerObserver {
//                    NotificationCenter.default.removeObserver(observer)
//                    self.playerObserver = nil
//                }
//            }
//        }
//    }
//    
//    @objc private func audioDidFinishPlaying() {
//        if let indexPath = currentPlayingIndex {
//            currentPlayingIndex = nil
//            tableView.reloadRows(at: [indexPath], with: .none)
//        }
//    }
//    
//    func resetPlaybackState() {
//        audioQueue.async { [weak self] in
//            self?.audioPlayer?.pause()
//            self?.audioPlayer = nil
//        }
//        
//        DispatchQueue.main.async { [weak self] in
//            self?.currentPlayingIndex = nil
//            self?.tableView.reloadData()
//        }
//    }
//}
//
//extension MusicView {
//    func setupTableView() {
//        tableView.delegate = self
//        tableView.dataSource = self
//        tableView.register(MusicCell.self)
//        tableView.separatorStyle = .none
//    }
//    
//    func setupView() {
//        subviews {
//            grayView
//            titleLB
//            tableView
//        }
//    }
//    
//    func styleView() {
//        grayView.style {
//            $0.backgroundColor = .hexA5A5A5
//            $0.clipsToBounds = true
//        }
//        
//        titleLB.style {
//            $0.text = Localized.Camera.addMusic
//            $0.font = UIFont.sfProDisplayBold(ofSize: 17)
//            $0.textColor = .hex212121
//        }
//    }
//    
//    func constraint() {
//        grayView
//            .width(36)
//            .height(5)
//            .top(8)
//            .centerHorizontally()
//        
//        titleLB
//            .centerHorizontally()
//            .Top == grayView.Bottom + 12
//        
//        tableView
//            .left(0)
//            .right(0)
//            .bottom(0)
//            .Top == titleLB.Bottom + 0
//    }
//}
//
//// MARK: - TableView Delegate, Datasource
//extension MusicView: UITableViewDataSource {
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return audioItems.count
//    }
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell: MusicCell = tableView.dequeueReuseableCell(for: indexPath)
//        let audioItem = audioItems[indexPath.row]
//        
//        cell.configure(with: audioItem)
//        cell.isPlaying = (indexPath == currentPlayingIndex)
//        cell.onPlayPauseTapped = { [weak self] in
//            guard let self = self else { return }
//            
//            // Các action cần cập nhật UI
//            var indexPathsToReload: [IndexPath] = []
//            
//            // Nếu đang phát nhạc ở cell khác, thêm cell đó vào danh sách cần reload
//            if let oldIndex = self.currentPlayingIndex, oldIndex != indexPath {
//                indexPathsToReload.append(oldIndex)
//            }
//            
//            // Kiểm tra nếu đang phát tại cell này
//            if self.currentPlayingIndex == indexPath {
//                // Dừng phát nhạc
//                self.stopAudio()
//                self.currentPlayingIndex = nil
//            } else {
//                // Phát nhạc mới
//                self.playAudio(at: indexPath)
//                self.currentPlayingIndex = indexPath
//            }
//            
//            // Thêm cell hiện tại vào danh sách reload
//            indexPathsToReload.append(indexPath)
//            
//            // Reload các cell cần thiết
//            if !indexPathsToReload.isEmpty {
//                tableView.reloadRows(at: indexPathsToReload, with: .none)
//            }
//        }
//        return cell
//    }
//    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let audioItem = audioItems[indexPath.row]
//        delegate?.didSelectMusic(title: audioItem.name)
//        print("Selected music: \(audioItem.name)")
//    }
//}
//
//extension MusicView: UITableViewDelegate {
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 80
//    }
//}
