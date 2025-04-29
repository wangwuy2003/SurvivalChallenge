//
//  IntroVC.swift
//  SurvivalChallenge
//
//  Created by Apple on 12/4/25.
//

import UIKit

class IntroVC: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var continueButton: InnerShadowButton!
    private var currentPageIndex = 0
    private var isScrollingByButton = false
    private var imgModel: [String] = ["bg_intro_0", "bg_intro_1", "bg_intro_2"]
    private var titleModel: [String] = []
    
    private let homeViewModel: HomeViewModel
    
    init(homeViewModel: HomeViewModel) {
        self.homeViewModel = homeViewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        configModel()
        configCollectionView()
        print(Localized.Intro.intro1)
    }
    
    @IBAction func didTapContinue(_ sender: Any) {
        if isScrollingByButton == false {
            switch currentPageIndex {
            case 0:
                nextCell(index: 1)
            case 1:
                nextCell(index: 2)
            case 2:
                pushContainerVC()
            default:
                break
            }
        }
    }
}

extension IntroVC {
    private func pushContainerVC() {
//        let vc = IAPVC()
//        vc.nameIAP = "Intro"
//        vc.isSplashPush = true
//        self.navigationController?.setViewControllers([vc], animated: false)
        
        let containerVC = ContainerVC()
        navigationController?.pushViewController(containerVC, animated: false)
//        navigationController?.setViewControllers([containerVC], animated: false)
    }
    
    private func nextCell(index: Int) {
        let indexPath = IndexPath(item: index, section: 0)
        collectionView.performBatchUpdates({ [weak self] in
            guard let self  = self else { return }
            self.collectionView.reloadData()
        }) { [weak self] _ in
            guard let self = self else { return }
            self.currentPageIndex = index
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            self.collectionView.collectionViewLayout.invalidateLayout()
            
            if let visibleCells = self.collectionView.visibleCells as? [IntroCVC], !visibleCells.isEmpty {
                for cell in visibleCells {
                    cell.updatePageControl(for: index)
                }
            }
        }
    }
}

extension IntroVC {
    private func configCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.scrollDirection = .horizontal
        }
        
        collectionView.register(UINib(nibName: "IntroCVC", bundle: nil), forCellWithReuseIdentifier: "IntroCVC")
    }
    
    private func configModel() {
        titleModel = [
            Localized.Intro.intro1,
            Localized.Intro.intro2,
            Localized.Intro.intro3
        ]
    }
    
    func setupViews() {
        continueButton.titleLabel?.font = UIFont.sfProDisplayBold(ofSize: 17)
        continueButton.layer.cornerRadius = continueButton.frame.height / 2
        continueButton.shadows = [
            InnerShadow(color: UIColor.white.withAlphaComponent(0.25), offset: CGSize(width: 0, height: 2), blur: 4),
            InnerShadow(color: .hex3853B4, offset: CGSize(width: 0, height: -2), blur: 4)
        ]
        continueButton.clipsToBounds = true
        continueButton.layoutIfNeeded()
    }
}

extension IntroVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        3
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "IntroCVC", for: indexPath) as? IntroCVC else {
            return UICollectionViewCell()
        }
        
        let index = indexPath.row
        cell.backgroundImage.image = UIImage(named: imgModel[index])
        cell.titleLB.text = titleModel[index]
        cell.updatePageControl(for: index)
        return cell
    }
}

extension IntroVC: UICollectionViewDelegate, UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            isScrollingByButton = true
        }
        
        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            isScrollingByButton = false
        }
        
        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            isScrollingByButton = false
        }
        
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let width = scrollView.frame.width
        let currentPage = Int((scrollView.contentOffset.x + width / 2) / width)
        if currentPage != currentPageIndex {
            if currentPage >= 0 && currentPage <= 2 {
                currentPageIndex = currentPage
                if let visibleCells = collectionView.visibleCells as? [IntroCVC], !visibleCells.isEmpty {
                    for cell in visibleCells {
                        cell.updatePageControl(for: currentPage)
                    }
                }
            }
        }
    }
}

extension IntroVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width
        let height = collectionView.bounds.height
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
}


