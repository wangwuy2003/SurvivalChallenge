//
//  SettingVC.swift
//  SurvivalChallenge
//
//  Created by Apple on 14/4/25.
//

import UIKit
import Stevia

class SettingVC: UIViewController {

    @IBOutlet weak var titleLB: UILabel!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var languageLB: UILabel!
    @IBOutlet weak var policyLB: UILabel!
    @IBOutlet weak var termOfUseLB: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    @IBAction func didTapBackBtn(_ sender: Any) {
        navigationController?.popViewController(animated: false)
    }
    
    @IBAction func didTapLanguageBtn(_ sender: Any) {
        navigationController?.pushViewController(LanguageVC(), animated: false)
    }
    
    @IBAction func didTapPolicyBtn(_ sender: Any) {
        print("Policy clicked...")
    }
    
    @IBAction func didTapTermOfUseBtn(_ sender: Any) {
        print("Term of use clicked...")
    }
}

// MARK: - Setup View
extension SettingVC {
    func setupViews() {
        view.clipsToBounds = false
        titleLB.style {
            $0.text = Localized.Setting.setting
            $0.font = UIFont.sfProDisplayBold(ofSize: 20)
        }
        
        stackView.style {
            $0.clipsToBounds = false
            $0.arrangedSubviews.forEach { view in
                view.clipsToBounds = false
                view.layer.masksToBounds = false
                view.backgroundColor = .white
                view.layer.cornerRadius = 16
                
                view.layer.shadowColor = UIColor.black.cgColor
                view.layer.shadowOffset = CGSize(width: 0, height: 2)
                view.layer.shadowRadius = 8
                view.layer.shadowOpacity = 0.12
                view.layer.shadowPath = UIBezierPath(roundedRect: view.bounds, cornerRadius: 16).cgPath
            }
        }
        
        languageLB.style {
            $0.text = Localized.Setting.language
            $0.font = UIFont.sfProDisplayBold(ofSize: 15)
        }
        
        policyLB.style {
            $0.text = Localized.Setting.privacyPolicy
            $0.font = UIFont.sfProDisplayBold(ofSize: 15)
        }
        
        termOfUseLB.style {
            $0.text = Localized.Setting.termOfUse
            $0.font = UIFont.sfProDisplayBold(ofSize: 15)
        }
    }
}
