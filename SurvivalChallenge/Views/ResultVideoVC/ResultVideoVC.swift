//
//  VideoVC.swift
//  SurvivalChallenge
//
//  Created by Apple on 16/4/25.
//

import UIKit
import Stevia

class ResultVideoVC: UIViewController {
    @IBOutlet weak var saveButton: InnerShadowButton!
    var videoIndex: Int?
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        if let index = videoIndex {
            print("Displaying video at index: \(index)")
        }
    }
    
    @IBAction func didTapBackBtn(_ sender: Any) {
        navigationController?.popViewController(animated: false)
    }
    
    @IBAction func didTapMenuBtn(_ sender: Any) {
        
    }
}

extension ResultVideoVC {
    func setupViews() {
        saveButton.style {
            $0.layoutIfNeeded()
            $0.clipsToBounds = true
            $0.titleLabel?.text = Localized.Video.save
            $0.titleLabel?.font = UIFont.sfProDisplayBold(ofSize: 17)
            $0.shadows = [
                InnerShadow(color: UIColor.white.withAlphaComponent(0.8), offset: CGSize(width: 0, height: 2), blur: 4),
                InnerShadow(color: .hex3853B4, offset: CGSize(width: 0, height: -2), blur: 4)
            ]
            $0.layer.cornerRadius = $0.frame.height / 2
        }
    }
}
