//
//  CameraCollectionViewCell.swift
//  EyeTrendFilter
//
//  Created by Hồ Hữu Nhân on 16/4/25.
//

import UIKit
import AlamofireImage

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
        if let url = URL(string: challenge.thumpFilter ?? "") {
            let placeHolder = UIImage.placeholder
            
            let cacheKey = url.absoluteString
            
            imageView.af.setImage(
                withURL: url,
                cacheKey: cacheKey,
                placeholderImage: placeHolder,
                imageTransition: .crossDissolve(0.2)
            )
        }
    }
}

