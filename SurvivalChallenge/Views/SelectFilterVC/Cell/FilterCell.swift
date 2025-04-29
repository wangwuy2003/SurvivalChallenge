//
//  FilterCell.swift
//  SurvivalChallenge
//
//  Created by Apple on 17/4/25.
//

import UIKit
import Stevia
import SDWebImage

class FilterCell: UICollectionViewCell {

    @IBOutlet weak var bgImage: UIImageView!
    @IBOutlet weak var tickSelectImage: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }

    func setupView() {
        clipsToBounds = false
        bgImage.style {
            $0.layer.cornerRadius = 8
            $0.clipsToBounds = true
        }
        tickSelectImage.isHidden = true
    }
    
    func configure(with challenge: SurvivalChallengeEntity, isSelected: Bool) {
        if let filterUrl = challenge.thumpFilter, let url = URL(string: filterUrl) {
            bgImage.sd_setImage(
                with: url,
                placeholderImage: UIImage(named: "placeholder"),
                options: [.progressiveLoad, .highPriority]
            )
        } else {
            bgImage.image = UIImage(named: "placeholder")
        }
        
        tickSelectImage.isHidden = !isSelected
    }
    
    private func loadImage(for urlString: String, into imageView: UIImageView, placeholder: UIImage?) {
        // Kiểm tra bộ nhớ đệm
        if let cachedImage = ImageCacheManager.shared.getImage(for: urlString) {
            imageView.image = cachedImage
            return
        }
        
        // Hiển thị ảnh placeholder khi đang tải
        imageView.image = placeholder
        
        // Tải ảnh từ mạng
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                return
            }
            
            // Lưu ảnh vào cache và cập nhật UI
            ImageCacheManager.shared.saveImage(image, for: urlString)
            DispatchQueue.main.async {
                imageView.image = image
            }
        }.resume()
    }
}
