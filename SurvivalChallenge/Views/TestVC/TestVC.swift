//
//  TestVC.swift
//  SurvivalChallenge
//
//  Created by Apple on 19/4/25.
//

import UIKit
import Stevia

class TestVC: UIViewController {
    var rankingView: RankingView?
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        config()
    }
    
    func config() {
        setupRankingView()
    }
}

extension TestVC {
    func setupRankingView() {
        guard let rankingView = Bundle.main.loadNibNamed("RankingView", owner: self, options: nil)?.first as? RankingView else {
            return
        }
        
        self.rankingView = rankingView
        rankingView.translatesAutoresizingMaskIntoConstraints = false
        rankingView.isHidden = false
        rankingView.designType = .rankingType3
        view.addSubview(rankingView)
        
        rankingView
            .top(75)
            .height(548)
            .width(130)
            .centerHorizontally()
    }
}
