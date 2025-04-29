//
//  ColoringView.swift
//  SurvivalChallenge
//
//  Created by Apple on 21/4/25.
//

import UIKit

class ColoringView: UIView {

    @IBOutlet weak var targetImageView: UIImageView!
    @IBOutlet weak var paintImageView: UIImageView!
    
    var designType: DesignType? = .coloringType1 {
        didSet {
            updateLayout()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateLayout()
    }
}

extension ColoringView {
    func updateLayout() {
        switch designType {
        case .coloringType1:
            targetImageView.image = .coloring1
            paintImageView.image = .paint1
        case .coloringType2:
            targetImageView.image = .coloring2
            paintImageView.image = .paint2
        case .coloringType3:
            targetImageView.image = .coloring3
            paintImageView.image = .paint3
        case .coloringType4:
            targetImageView.image = .coloring4
            paintImageView.image = .paint4
        case .coloringType5:
            targetImageView.image = .coloring5
            paintImageView.image = .paint5
        default:
            break
        }
    }
}
