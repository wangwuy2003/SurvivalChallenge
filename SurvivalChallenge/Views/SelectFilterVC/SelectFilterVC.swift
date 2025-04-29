//
//  SelectFilterVC.swift
//  SurvivalChallenge
//
//  Created by Apple on 17/4/25.
//

import UIKit
import Stevia

protocol SelectFilterDelegate: AnyObject {
    func didSelectFilter(at index: Int)
}

class SelectFilterVC: UIViewController {
    weak var delegate: SelectFilterDelegate?
    
    @IBOutlet weak var titleLB: UILabel!
    @IBOutlet weak var saveButton: InnerShadowButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
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
            print("No filterselected")
            return
        }
        
        delegate?.didSelectFilter(at: selectedIndex)
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
        return HomeViewModel.shared.numberOfAllItems
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterCell", for: indexPath) as? FilterCell else {
            return UICollectionViewCell()
        }
        let challenge = HomeViewModel.shared.challengeAll(at: indexPath.item)
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
        return CGSize(width: 110, height: 110)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        6
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        6
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
            return UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
    }
}
