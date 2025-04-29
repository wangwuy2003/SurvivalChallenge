//
//  CameraCollectionViewCell.swift
//  EyeTrendFilter
//
//  Created by Hồ Hữu Nhân on 16/4/25.
//

import UIKit


class FilterCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var unfocusWidth: NSLayoutConstraint!
    @IBOutlet weak var focusWidth: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.clipsToBounds = true
        contentView.layer.masksToBounds = true
        contentView.layer.cornerRadius = 26
    }
    
    func configCell(imageName: String) {
        imageView.image = UIImage(named: imageName)
    }
    
    func configure(with challenge: SurvivalChallengeEntity) {
        if let thumpUrl = challenge.thumpFilter, let url = URL(string: thumpUrl) {
            imageView.sd_setImage(
                with: url,
                placeholderImage: UIImage(named: "placeholder"),
                options: [.progressiveLoad, .highPriority]
            )
        } else {
            imageView.image = UIImage(named: "placeholder")
        }
    }
}

