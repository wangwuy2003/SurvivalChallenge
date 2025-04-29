//
//  ChallengeCell.swift
//  SurvivalChallenge
//
//  Created by Apple on 14/4/25.
//

import UIKit
import Stevia
import SDWebImage

class ChallengeCell: UICollectionViewCell {

    @IBOutlet weak var picture: UIImageView!
    @IBOutlet weak var descriptionLB: UILabel!
    @IBOutlet weak var titleLB: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func configure(with challenge: SurvivalChallengeEntity) {
        
        print("yolo Configuring cell with title: \(challenge.username)")
        print("yolo Description: \(challenge.textDes)")
        titleLB.text = challenge.username
        descriptionLB.text = challenge.textDes
        
        if let thumbnailUrl = challenge.thumpUrl, let url = URL(string: thumbnailUrl) {
            picture.sd_setImage(
                with: url,
                placeholderImage: .placeholder,
                options: [.progressiveLoad, .highPriority]
            )
        } else {
            picture.image = .placeholder
        }
    }
    
    func setupView() {
        self.clipsToBounds = false
        
        self.layer.cornerRadius = 12
        self.layer.borderWidth = 1.5
        self.layer.borderColor = UIColor.hex212121.cgColor
        
        self.layer.shadowColor = UIColor.hexFFA1A1.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 4)
        self.layer.shadowOpacity = 1
        self.layer.shadowRadius = 1
        
        self.contentView.layer.cornerRadius = 12
        self.contentView.clipsToBounds = true
        
        picture.style {
            $0.layer.cornerRadius = 12
        }
        
        titleLB.style {
            $0.text = "Title LB here"
            $0.font = UIFont.sfProDisplayBold(ofSize: 17)
            $0.textColor = .hex212121
        }
        
        descriptionLB.style {
            $0.text = "Title LB here"
            $0.font = UIFont.sfProDisplayRegular(ofSize: 13)
            $0.textColor = .hex212121.withAlphaComponent(0.8)
        }
    }
}
