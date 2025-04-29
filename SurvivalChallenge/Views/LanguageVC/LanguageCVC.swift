//
//  LanguageCVC.swift
//  Authenticator IOS Source
//
//  Created by Tran Nghia Pro on 29/11/24.
//

import UIKit

class LanguageCVC: UICollectionViewCell {

    @IBOutlet weak var languageImg: UIImageView!
    @IBOutlet weak var languageLbl: UILabel!
    @IBOutlet weak var selectImg: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        clipsToBounds = false
        layer.masksToBounds = false
        
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateShadow()
        
        layer.cornerRadius = 12
    }
    
    func setupCellSelected() {
        backgroundColor = .hexC8D4FF
        layer.borderWidth = 2
        layer.borderColor = UIColor.clear.cgColor
        languageLbl.font = UIFont.sfProDisplayMedium(ofSize: 15)
        selectImg.image = UIImage(named: "language_selected_img")
    }
    
    func setupCell() {
        backgroundColor = UIColor.white
        layer.borderWidth = 2
        layer.borderColor = UIColor.clear.cgColor
        languageLbl.font = UIFont.sfProDisplayMedium(ofSize: 15)
        selectImg.image = UIImage(named: "language_unselected_img")
    }
    
    private func updateShadow() {
        layer.shadowColor = UIColor.hex0000001F.cgColor
        layer.shadowPath = UIBezierPath(roundedRect: self.bounds,
                                        cornerRadius: self.layer.cornerRadius).cgPath
        layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
        layer.shadowOpacity = 0.7
        layer.shadowRadius = 10.0
    }
    
    override func prepareForReuse() {
        languageLbl.text = ""
        languageImg.image = nil
        selectImg.image = nil
    }
}
