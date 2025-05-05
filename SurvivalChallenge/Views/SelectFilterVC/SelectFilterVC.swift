//
//  SelectFilterVC.swift
//  SurvivalChallenge
//
//  Created by Apple on 17/4/25.
//

import UIKit
import Stevia

protocol SelectFilterDelegate: AnyObject {
    func didSelectFilter(challenge: SurvivalChallengeEntity)
}

class SelectFilterVC: UIViewController {
    weak var delegate: SelectFilterDelegate?
    
    @IBOutlet weak var titleLB: UILabel!
    @IBOutlet weak var saveButton: InnerShadowButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
    let challenges: [SurvivalChallengeEntity] = HomeViewModel.shared.allChallenges
    
    private var selectedIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupCollectionView()
    }

    @IBAction func didTapBackBtn(_ sender: Any) {
        navigationController?.popViewController(animated: false)
    }
    
    @IBAction func didTapSaveBtn(_ sender: Any) {
        guard let selectedIndex = selectedIndex else {
            print("No filter selected")
            return
        }
        
        // Get the selected challenge from the array
        let selectedChallenge = challenges[selectedIndex]
        
        // Pass the challenge object to the delegate method
        delegate?.didSelectFilter(challenge: selectedChallenge)
        navigationController?.popViewController(animated: false)
    }
    
    private func observeViewModelUpdates() {
        HomeViewModel.shared.onDataUpdated = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
}

extension SelectFilterVC {
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "FilterCell", bundle: nil), forCellWithReuseIdentifier: "FilterCell")
        
        // Configure the layout for 3 items per row
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.minimumInteritemSpacing = 8
            flowLayout.minimumLineSpacing = 8
            flowLayout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        }
    }
    
    func setupViews() {
        saveButton.style {
            $0.titleLabel?.font = UIFont.sfProDisplayBold(ofSize: 13)
            $0.titleLabel?.text = Localized.Video.save
            $0.layer.cornerRadius = $0.frame.height / 2
            $0.shadows = [
                InnerShadow(color: UIColor.white.withAlphaComponent(0.5), offset: CGSize(width: 0, height: 2), blur: 4),
                InnerShadow(color: .hex3853B4, offset: CGSize(width: 0, height: -2), blur: 4)
            ]
            $0.clipsToBounds = true
        }
    }
}

extension SelectFilterVC: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return challenges.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterCell", for: indexPath) as? FilterCell else {
            return UICollectionViewCell()
        }
        let challenge = challenges[indexPath.item]
        let isSelected = (indexPath.item == selectedIndex)
        cell.configure(with: challenge, isSelected: isSelected)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if selectedIndex == indexPath.item {
           return
       }
       
       let previousSelectedIndex = selectedIndex
       selectedIndex = indexPath.item
       
       var indexPathsToReload = [indexPath]
       if let previousIndex = previousSelectedIndex {
           indexPathsToReload.append(IndexPath(item: previousIndex, section: 0))
       }
       
       collectionView.reloadItems(at: indexPathsToReload)
    }
}

extension SelectFilterVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Calculate the width for 3 items per row with spacing
        let totalSpacing: CGFloat = 8 * 4 // 8 points spacing × (3 items + 1 edge) = 32 points
        let availableWidth = collectionView.bounds.width - totalSpacing
        let itemWidth = availableWidth / 3
        
        return CGSize(width: itemWidth, height: itemWidth) // Square cells
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8 // Vertical spacing between rows
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8 // Horizontal spacing between items
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8) // Padding around the entire collection
    }
}
