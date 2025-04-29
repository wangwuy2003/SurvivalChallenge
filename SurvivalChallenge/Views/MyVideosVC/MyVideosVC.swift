//
//  MyVideosVC.swift
//  SurvivalChallenge
//
//  Created by Apple on 16/4/25.
//

import UIKit
import Stevia

class MyVideosVC: UIViewController {

    @IBOutlet weak var titleLB: UILabel!
    @IBOutlet weak var strokeTitleLB: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupCollectionView()
    }
    
    @IBAction func didTapSettingBtn(_ sender: Any) {
        navigationController?.pushViewController(SettingVC(), animated: false)
    }
}

extension MyVideosVC {
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "MyVideoCell", bundle: nil), forCellWithReuseIdentifier: "MyVideoCell")
    }
    
    func setupViews() {
        titleLB.style {
            $0.clipsToBounds = true
            strokeTitleLB.text = Localized.MyVideos.myVideos
            strokeTitleLB.font = UIFont.luckiestGuyRegular(ofSize: 28)
            strokeTitleLB.textColor = .hex212121
            let strokeAttr: [NSAttributedString.Key: Any] = [
                .strokeColor: UIColor.hex212121,
                .foregroundColor: UIColor.hex212121,
                .strokeWidth: 5
            ]
            strokeTitleLB.attributedText = NSAttributedString(string: strokeTitleLB.text!, attributes: strokeAttr)
     
            titleLB.text = strokeTitleLB.text
            titleLB.font = strokeTitleLB.font
            titleLB.layer.shadowColor = UIColor.hex431B00.cgColor
            titleLB.layer.shadowOffset = CGSize(width: 0, height: 4)
            titleLB.layer.shadowOpacity = 1
            titleLB.layer.shadowRadius = 0
            
            let success = $0.applyGradientWith(
                startColor: .hexFFA1A1,
                endColor: .hex4E75FF,
                direction: .leftToRight
            )
            if !success {
                print("Failed to apply gradient to label")
            }
        }
    }
}

extension MyVideosVC {
    // MARK: - Alert: Confirm Delete
    private func showConfirmAlert(for indexPath: IndexPath) {
        let alert = UIAlertController(title: "", message: Localized.MyVideos.deleteYourVideo, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.MyVideos.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: Localized.MyVideos.delete, style: .destructive, handler: { [weak self] _ in
            print("delete...")
        }))
        present(alert, animated: true)
    }
    
    // MARK: - ContextMenu
    private func contextMenuActions(for indexPath: IndexPath) -> UIMenu {
        return UIMenu(children: [
            UIAction(title: Localized.MyVideos.share, image: .upload, handler: { [weak self] _ in
                guard let self = self else { return }
            }),
            UIAction(title: Localized.MyVideos.delete, image: .trashIc, handler: { [weak self] _ in
                self?.showConfirmAlert(for: indexPath)
            })
        ])
    }
}

// MARK: - Collection View
extension MyVideosVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyVideoCell", for: indexPath) as? MyVideoCell else {
            return UICollectionViewCell()
        }
        
        let menu = contextMenuActions(for: indexPath)
        cell.updateMenu(with: menu)
        cell.toggleSelection = { [weak self] in
            self?.collectionView.reloadData()
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let resultVideoVC = ResultVideoVC()
        resultVideoVC.videoIndex = indexPath.row
        navigationController?.pushViewController(resultVideoVC, animated: false)
    }
}

extension MyVideosVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point: CGPoint) -> UIContextMenuConfiguration? {
        
        guard let indexPath = indexPaths.first else { return nil }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            return self?.contextMenuActions(for: indexPath)
        }
    }
}

extension MyVideosVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = Utils.isIpad() ? 56 : 16
        let totalPadding = padding * 2
        let interitemSpacing: CGFloat = 10
        let totalWidth = UIScreen.main.bounds.width - totalPadding - interitemSpacing
        let itemWidth = totalWidth / 2
        
        return CGSize(width: Int(itemWidth), height: 266)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        20
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let padding: CGFloat = Utils.isIpad() ? 56 : 16
        return UIEdgeInsets(top: 0, left: padding, bottom: 0, right: padding)
    }
}

