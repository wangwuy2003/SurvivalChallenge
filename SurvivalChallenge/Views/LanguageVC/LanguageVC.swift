//
//  LanguageVC.swift
//  Face_AI_IOS
//
//  Created by Tran Nghia Pro on 17/9/24.
//

import UIKit

class LanguageVC: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var bgAds: UIView!
    @IBOutlet weak var languageLbl: UILabel!
    @IBOutlet weak var applyBtn: UIButton!
    @IBOutlet weak var backBtn: UIButton!
    
    
    
    var selectedFlag: Int = -1 {
        didSet {
            if selectedFlag != -1 {
                applyBtn.isEnabled = true
            }
        }
    }
    
    var bgNative1 = UIView()
    var bgNative2 = UIView()
    
    var firstSelected: Int = -1
    var isSplashPush = false
    private var languageVM: LanguageViewModel!
    private var firstLoad = true
    var reload: (() ->())?
    var homeViewModel: HomeViewModel?
    private lazy var introVC: IntroVC = {
        IntroVC(homeViewModel: homeViewModel ?? HomeViewModel())
    }()
    
    var addedNative2 = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if isSplashPush {
            backBtn.isHidden = true
        }
        setupViewModel()
        setupCollectionView()
    }

    private func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UINib(nibName: "LanguageCVC", bundle: nil), forCellWithReuseIdentifier: "LanguageCVC")
    }
    
    private func setupViewModel() {
        languageVM = LanguageViewModel()
        languageVM.selectedLanguage(selectedFlag: &selectedFlag, firstSelected: &firstSelected, isSplash: isSplashPush)
    }
    
    private func pushContainerVC() {
        if !isSplashPush {
            self.navigationController?.popViewController(animated: false)
        } else {
            self.navigationController?.pushViewController(introVC, animated: false)
        }
    }
    
    @IBAction func backClicked(_ sender: Any) {
        self.navigationController?.popViewController(animated: false)
    }
    
    @IBAction func applyClicked(_ sender: Any) {
        if firstSelected != selectedFlag {
            languageVM.changeLanguage(selectedFlag: selectedFlag, firstSelected: firstSelected)
            reload?()
        }
        pushContainerVC()
    }
}

extension LanguageVC: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        languageVM.getCountLanguage()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LanguageCVC", for: indexPath) as? LanguageCVC else { return UICollectionViewCell() }
        if selectedFlag == indexPath.row {
            cell.setupCellSelected()
        } else {
            cell.setupCell()
        }
        cell.languageLbl.text = languageVM.getName(index: indexPath.row)
        cell.languageImg.backgroundColor = .clear
        cell.languageImg.image = UIImage(named: "Countries_1_\(indexPath.row)")
        return cell
    }
    
}

extension LanguageVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedFlag = indexPath.row
        collectionView.reloadData()
    }
}

extension LanguageVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = Utils.isIpad() ? 56 : 20
        let totalPadding = padding * 2
        let width = Int(UIScreen.main.bounds.width - totalPadding)
        return CGSize(width: width, height: 64)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        12
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let padding: CGFloat = Utils.isIpad() ? 56 : 16
        return UIEdgeInsets(top: 0, left: padding, bottom: 0, right: padding)
    }
}
