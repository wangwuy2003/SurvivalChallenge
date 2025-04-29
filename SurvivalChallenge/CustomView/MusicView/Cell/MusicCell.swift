//
//  MusicCell.swift
//  SurvivalChallenge
//
//  Created by Apple on 17/4/25.
//

import UIKit
import Stevia

class MusicCell: UITableViewCell {
    private lazy var iconView = UIView()
    private lazy var iconImageView = UIImageView()
    private lazy var playOrPauseBtn = UIButton()
    private lazy var playOrPauseImage = UIImageView()
    private lazy var musicLB = UILabel()
    
    var isPlaying: Bool = false {
        didSet {
            updatePlayPauseUI()
        }
    }
    
    var onPlayPauseTapped: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
        styleview()
        constraint()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
    func updatePlayPauseUI() {
        playOrPauseImage.image = isPlaying ? .pauseIc : .playIc
    }
    
    func configure(with audioItem: SurvivalChallengeEntity) {
        musicLB.text = audioItem.name
    }
    
    @objc func didTapPlayOrPauseBtn(_ sender: Any) {
        print("Play pause clicked...")
        onPlayPauseTapped?()
    }
}

extension MusicCell {
    func setupView() {
        subviews {
            iconView
            musicLB
            playOrPauseImage
            playOrPauseBtn
        }
        
        iconView.subviews {
            iconImageView
        }
    }
    
    func styleview() {
        iconView.style {
            $0.layer.cornerRadius = 8
            $0.backgroundColor = .hex4E75FF.withAlphaComponent(0.25)
        }
        
        iconImageView.style {
            $0.image = .musicIc
        }
        
        musicLB.style {
            $0.text = "Sample"
            $0.font = UIFont.sfProDisplayMedium(ofSize: 15)
        }
        
        playOrPauseImage.style {
            $0.image = .playIc
        }
        
        playOrPauseBtn.style {
            $0.addTarget(self,
                         action: #selector(didTapPlayOrPauseBtn),
                         for: .touchDown)
        }
    }
    
    func constraint() {
        iconView
            .left(16)
            .width(44)
            .height(44)
            .centerVertically()
        
        iconImageView
            .width(24)
            .height(24)
            .centerInContainer()
        
        playOrPauseImage
            .right(14)
            .width(20)
            .height(20)
            .centerVertically()
        
        musicLB.Left == iconView.Right + 12
        musicLB.Right == playOrPauseImage.Left - 12
        musicLB.centerVertically()
        
        playOrPauseBtn.fillContainer()
    }
}
