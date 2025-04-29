//
//  MyVideoCell.swift
//  SurvivalChallenge
//
//  Created by Apple on 16/4/25.
//

import UIKit
import Stevia

class MyVideoCell: UICollectionViewCell {
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var menuButton: UIButton!
    
    var toggleSelection: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setupView() {
        clipsToBounds = false
        backgroundImage.style {
            $0.layer.cornerRadius = 8
            $0.clipsToBounds = true
        }
    }
    
    func updateMenu(with menu: UIMenu) {
        menuButton.menu = menu
        menuButton.showsMenuAsPrimaryAction = true
    }

    @IBAction func didTapActionBtn(_ sender: Any) {
        toggleSelection?()
    }
}
