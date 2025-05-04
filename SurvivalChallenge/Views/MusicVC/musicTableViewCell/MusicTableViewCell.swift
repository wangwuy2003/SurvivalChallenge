//
//  MusicTableViewCell.swift
//  EyeTrendFilter
//
//  Created by Hồ Hữu Nhân on 15/4/25.
//

import UIKit
import MiTuKit

protocol MusicTableViewCellDelegate: AnyObject {
    func didTapPlayButton(in cell: MusicTableViewCell)
    func didTapPauseButton()
}

class MusicTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    
    var isPlaying: Bool = false {
        didSet {
            playButton.setImage(isPlaying ? .pauseIc : .playIc, for: .normal)
        }
    }
    
    weak var delegate: MusicTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configCell(model: SurvivalChallengeEntity, isPlaying: Bool) {
        titleLabel.text = model.name
        self.isPlaying = isPlaying
        
        playButton.handle { [weak self] in
            guard let self = self else { return }
            if self.isPlaying {
                self.delegate?.didTapPauseButton()
            } else {
                self.delegate?.didTapPlayButton(in: self)
            }
        }
    }
}
