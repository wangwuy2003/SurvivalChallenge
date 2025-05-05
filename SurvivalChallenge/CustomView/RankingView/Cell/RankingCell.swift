//
//  RankingCell.swift
//  SurvivalChallenge
//
//  Created by Apple on 19/4/25.
//

import UIKit
import Stevia

class RankingCell: UICollectionViewCell {

    @IBOutlet weak var bgImage: UIImageView!
    @IBOutlet weak var numberLB: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = 8
        self.clipsToBounds = false
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bgImage.image = nil
        bgImage.isHidden = true
        numberLB.transform = .identity
    }
    
    func setupView() {
        bgImage.isHidden = true
        numberLB.style {
            $0.transform = .identity
            $0.font = UIFont.sfProDisplayBold(ofSize: 20)
            $0.textColor = .white
            $0.layer.shadowColor = UIColor.black.withAlphaComponent(0.12).cgColor
            $0.layer.shadowOffset = CGSize(width: 0, height: 2)
            $0.layer.shadowOpacity = 1
            $0.layer.shadowRadius = 8
            $0.layer.masksToBounds = false
        }
    }
    
    func configureCell(style: RankingCellStyle, index: Int) {
        bindData(index: index)
        
        switch style {
        case .case1, .case2:
            numberLB.textColor = .white
            numberLB.font = UIFont.sfProDisplayBold(ofSize: 20)
            numberLB.layer.borderWidth = 0
            self.layer.borderWidth = 0
            self.backgroundColor = .hex3D3D3D40
        case .case3:
            numberLB.textColor = .white
            numberLB.font = UIFont.sfProDisplayBold(ofSize: 20)
            let strokeTextAttributes: [NSAttributedString.Key: Any] = [
                .strokeColor: UIColor.hex212121,
                .foregroundColor: UIColor.white,
                .strokeWidth: -2.0,
                .font: UIFont.sfProDisplayBold(ofSize: 20)
            ]
            numberLB.attributedText = NSAttributedString(string: "\(index + 1)", attributes: strokeTextAttributes)
            self.layer.borderWidth = 1
            self.layer.borderColor = UIColor.hex212121.cgColor
            self.backgroundColor = .white
        }
    }
    
    func animateSelection() {
        bgImage.isHidden = false
        
        UIView.animate(withDuration: 0.3) {
            self.numberLB.transform = CGAffineTransform(translationX: -self.bounds.width + 5, y: 0)
        }
    }
    
    func bindData(index: Int) {
        numberLB.text = "\(index + 1)"
    }
}
