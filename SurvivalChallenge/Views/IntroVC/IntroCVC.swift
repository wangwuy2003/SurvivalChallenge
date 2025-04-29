//
//  IntroCVC.swift
//  SurvivalChallenge
//
//  Created by Apple on 13/4/25.
//

import UIKit
import Stevia

class IntroCVC: UICollectionViewCell {
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var titleLB: UILabel!
    @IBOutlet weak var descriptionView: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
        setupPageControl()
    }
    
    func setupView() {
        backgroundImage.height(414 * screenHeight)
        descriptionView.height(350 * screenHeight)
        descriptionView.style {
            $0.layer.cornerRadius = 20
            $0.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
            $0.clipsToBounds = true
        }
    }
    
    private func setupPageControl() {
        let selected = UIImage.selectedPagecontrol
        pageControl.pageIndicatorTintColor = .hex3D3D3D40
        pageControl.currentPageIndicatorTintColor = .hex212121
        pageControl.setIndicatorImage(selected, forPage: pageControl.currentPage)
    }
    
    func updatePageControl(for index: Int) {
        pageControl.currentPage = index
        if let selectedImage = UIImage(named: "selected_pagecontrol") {
            for page in 0..<pageControl.numberOfPages {
                pageControl.setIndicatorImage(page == index ? selectedImage : nil, forPage: page)
            }
        }
    }
}
