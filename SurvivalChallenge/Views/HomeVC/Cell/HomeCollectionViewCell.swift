//
//  HomeCollectionViewCell.swift
//  EyeTrendFilter
//
//  Created by Hồ Hữu Nhân on 14/4/25.
//

import UIKit
import MiTuKit
import AlamofireImage

class HomeCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        contentView.clipsToBounds = false
        containerView.clipsToBounds = false
        containerView.layer.shadowColor = UIColor.from("FF9FC2").cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowOpacity = 1
        containerView.layer.shadowRadius = 0
    }
    
    func configureCell(model: SurvivalChallengeEntity) {
        self.titleLabel.text = model.username
        self.descriptionLabel.text = model.textDes
        
        if let url = URL(string: model.thumpUrl ?? "") {
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
