//
//  MyVideoCell.swift
//  SurvivalChallenge
//
//  Created by Apple on 16/4/25.
//

import UIKit
import MiTuKit

protocol MyVideoCellDelegate: AnyObject {
    func didSelectShare(at cell: MyVideoCell)
    func didSelectDelete(at cell: MyVideoCell)
}

class MyVideoCell: UICollectionViewCell {
    
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var containerView: UIView!
    
    weak var delegate: MyVideoCellDelegate?
    
    var toggleSelection: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.clipsToBounds = false
        containerView.clipsToBounds = false
        
        setupContextMenu()
    }
    
    func updateMenu(with menu: UIMenu) {
        menuButton.menu = menu
        menuButton.showsMenuAsPrimaryAction = true
    }
    
    func configureCell(video: URL) {
        Task { [weak self] in
            guard let self = self else { return }
            let image = await FileHelper.shared.getThumbnail(for: video)
            DispatchQueue.main.async {
                self.thumbnailImageView.image = image ?? .placeholder
            }
        }
    }

    @IBAction func didTapActionBtn(_ sender: Any) {
        toggleSelection?()
    }
    
    private func setupContextMenu() {
        let share = UIAction(title: Localized.MyVideos.share,
                             image: .upload) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.didSelectShare(at: self)
        }
        
        let delete = UIAction(title: Localized.MyVideos.delete,
                              image: .trashIc,
                              attributes: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.didSelectDelete(at: self)
        }
        
        let menu = UIMenu(title: "", children: [share, delete])
        menuButton.showsMenuAsPrimaryAction = true
        menuButton.menu = menu
    }
}
