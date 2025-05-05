//
//  MyVideosVC.swift
//  SurvivalChallenge
//
//  Created by Apple on 16/4/25.
//

import UIKit
import Stevia
import MiTuKit

class MyVideosVC: UIViewController {

    @IBOutlet weak var emptyLB: UILabel!
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var titleLB: UILabel!
    @IBOutlet weak var strokeTitleLB: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var videoList: [URL] = [] {
        didSet {
            emptyView.isHidden = !videoList.isEmpty
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupCollectionView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: .didSaveVideo, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getData()
    }
    
    @IBAction func didTapSettingBtn(_ sender: Any) {
        navigationController?.pushViewController(SettingVC(), animated: false)
    }
}

extension MyVideosVC {
    @objc func getData() {
        self.videoList = FileHelper.shared.getAllVideosInRecordFolder()
        self.collectionView.reloadData()
    }
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "MyVideoCell", bundle: nil), forCellWithReuseIdentifier: "MyVideoCell")
    }
    
    func setupViews() {
        emptyLB.style {
            $0.text = Localized.MyVideos.emptyFolder
        }
        
        emptyView.style {
            $0.isHidden = true
        }
        
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

// MARK: - Collection View
extension MyVideosVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videoList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyVideoCell", for: indexPath) as? MyVideoCell else {
            return UICollectionViewCell()
        }
        
        cell.delegate = self
        cell.configureCell(video: videoList[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let videoURL = videoList[indexPath.row]
        let resultVideoVC = ResultVideoVC()
        resultVideoVC.videoURL = videoURL
        navigationController?.pushViewController(resultVideoVC, animated: false)
    }
}

extension MyVideosVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalItemPerRow = Utils.isIpad() ? 3.0 : 2.0
        let padding = Utils.isIpad() ? 24.0 : 16.0
        let gap = Utils.isIpad() ? 32.0 : 15.0
        let totalPadding: CGFloat = padding * 2 + gap * (totalItemPerRow - 1)
        let width = (maxWidth - totalPadding) / totalItemPerRow
        let height = Utils.isIpad() ? 360.0 : 243.0
        
        return CGSize(width: width, height: height)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return Utils.isIpad() ? 28 : 23
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return Utils.isIpad() ? 32 : 15
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let padding = Utils.isIpad() ? 24.0 : 16.0
        return UIEdgeInsets(top: 12, left: padding, bottom: 40, right: padding)
    }
}

//MARK: - MyVideoCellDelegate
extension MyVideosVC: MyVideoCellDelegate {
    func didSelectShare(at cell: MyVideoCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else {return}
        
        let videoURL = videoList[indexPath.row]
        
        self.share(items: [videoURL])
    }
    
    func didSelectDelete(at cell: MyVideoCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }

        let videoURL = videoList[indexPath.row]

        let alert = UIAlertController(
            title: Localized.MyVideos.deleteYourVideo,
            message: nil,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: Localized.MyVideos.cancel,
                                      style: .cancel,
                                      handler: nil))

        alert.addAction(UIAlertAction(title: Localized.MyVideos.delete,
                                      style: .destructive,
                                      handler: { _ in
            Task {
                let fileName = videoURL.lastPathComponent
                await FileHelper.shared.removeFile(fileName: fileName, from: .record)
                self.videoList.remove(at: indexPath.row)
                self.collectionView.deleteItems(at: [indexPath])
            }
        }))

        present(alert, animated: true, completion: nil)
    }
}
