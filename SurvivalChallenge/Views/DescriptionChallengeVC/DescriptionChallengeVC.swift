import UIKit
import Stevia
import AVKit
import AVFoundation

class DescriptionChallengeVC: UIViewController {
    @IBOutlet weak var videoPlayerView: UIView!
    @IBOutlet weak var usernameLB: UILabel!
    @IBOutlet weak var descriptionLB: UILabel!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var tryNowButton: InnerShadowButton!
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var playerItemObserver: NSKeyValueObservation?

    var textDes: String?
    var playerItem: AVPlayerItem?
    var username: String?
    
    var designType: DesignType?
    
    var challenge: SurvivalChallengeEntity?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupVideoPlayer()
        updateUI()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.pause()
        playerItemObserver?.invalidate()
        Utils.removeIndicator()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = videoPlayerView.bounds
        bottomView.layer.sublayers?.first?.frame = bottomView.bounds
    }

    @IBAction func didTapBackBtn(_ sender: Any) {
        navigationController?.popViewController(animated: false)
    }
    
    @IBAction func didTapTryNowBtn(_ sender: Any) {
        let cameraVC = CameraVC()
        cameraVC.designType = designType
        cameraVC.challenges = HomeViewModel.shared.allChallenges.prefix(13).map { $0 }
        cameraVC.selectedChallenge = challenge
        navigationController?.pushViewController(cameraVC, animated: false)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        playerItemObserver?.invalidate()
        Utils.removeIndicator()
    }
}

extension DescriptionChallengeVC {
    func setupViews() {
        tryNowButton.style {
            $0.backgroundColor = .hex4E75FF
            $0.setTitle(Localized.DescriptionChallenge.tryNow, for: .normal)
            $0.titleLabel?.font = UIFont.sfProDisplayBold(ofSize: 17)
            $0.setTitleColor(.white, for: .normal)
            $0.setImage(.videocameraIc, for: .normal)
            $0.layer.cornerRadius = $0.frame.height / 2
            $0.shadows = [
                InnerShadow(color: UIColor.white.withAlphaComponent(0.25), offset: CGSize(width: 0, height: 2), blur: 4),
                InnerShadow(color: .hex3853B4, offset: CGSize(width: 0, height: -2), blur: 4)
            ]
            $0.clipsToBounds = true
        }

        descriptionLB.style {
            $0.font = UIFont.sfProDisplayMedium(ofSize: 15)
        }

        usernameLB.style {
            $0.font = UIFont.sfProDisplayBold(ofSize: 17)
        }

        bottomView.translatesAutoresizingMaskIntoConstraints = false

        bottomView.style {
            $0.applyGradient(
                colours: [
                    UIColor.black.withAlphaComponent(0),
                    UIColor.black.withAlphaComponent(0.25)
                ],
                startPoint: CGPoint(x: 0.5, y: 0),
                endPoint: CGPoint(x: 0.5, y: 1)
            )
        }
    }
}

extension DescriptionChallengeVC {
    private func setupVideoPlayer() {
        guard let playerItem = playerItem else {
            print("No player item provided")
            Utils.removeIndicator()
            showVideoError()
            return
        }

        Utils.showIndicator()

        player = AVPlayer(playerItem: playerItem)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = videoPlayerView.bounds
        playerLayer?.videoGravity = .resizeAspectFill
        if let playerLayer = playerLayer {
            videoPlayerView.layer.insertSublayer(playerLayer, at: 0) // Below bottomView
        }

        playerItemObserver = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                switch item.status {
                case .readyToPlay:
                    Utils.removeIndicator()
                    self?.player?.play()
                case .failed:
                    Utils.removeIndicator()
                    self?.showVideoError()
                default:
                    Utils.showIndicator()
                }
            }
        }

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.play()
        }
    }

    private func showVideoError() {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Failed to load video"
        label.textColor = .white
        label.textAlignment = .center
        videoPlayerView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: videoPlayerView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: videoPlayerView.centerYAnchor)
        ])
        videoPlayerView.bringSubviewToFront(label)
    }

    private func updateUI() {
        descriptionLB.text = textDes ?? "No description"
        usernameLB.text = username ?? "Unknown user"
    }
}
