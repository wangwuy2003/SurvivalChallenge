//
//  ImageCacheManager.swift
//  SurvivalChallenge
//
//  Created by Apple on 21/4/25.
//

import UIKit

class ImageCacheManager {
    static let shared = ImageCacheManager()
    private let cache = NSCache<NSString, UIImage>()
    
    // Lưu ảnh vào cache
    func saveImage(_ image: UIImage, for url: String) {
        cache.setObject(image, forKey: url as NSString)
    }
    
    // Lấy ảnh từ cache
    func getImage(for url: String) -> UIImage? {
        return cache.object(forKey: url as NSString)
    }
    
    // Xóa ảnh khỏi cache (nếu cần)
    func removeImage(for url: String) {
        cache.removeObject(forKey: url as NSString)
    }
}
