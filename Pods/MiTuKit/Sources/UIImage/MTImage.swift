//
//  MTImage.swift
//  MiTuKit
//
//  Created by Hồ Minh Tường on 21/11/21.
//  Copyright © 2021 - Present MiTu Ultra

#if os(iOS)
import Foundation
import UIKit

public extension UIImage {
    func scale(toSize newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        self.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func resizeTopAlignedToFill(newWidth: CGFloat) -> UIImage? {
        let newHeight = size.height * newWidth / size.width

        let newSize = CGSize(width: newWidth, height: newHeight)

        UIGraphicsBeginImageContextWithOptions(newSize, false, UIScreen.main.scale)
        draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
    
    func resize(targetSize: CGSize) -> UIImage {
        let size = self.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    func toBase64(maxSize: Int? = nil, options: Data.Base64EncodingOptions = [], step: CGFloat = 0.05) -> String? {
        if let maxSize = maxSize {
            let data = self.resizeData(maxSize: maxSize, step: step)
            return data?.base64EncodedString(options: options)
        } else {
            let data = self.jpegData(compressionQuality: 1)
            return data?.base64EncodedString(options: options)
        }
    }
    
    func resizeData(maxSize: Int, step: CGFloat = 0.05) -> Data? {
        var quality: CGFloat = 1.0
        
        if let data = self.jpegData(compressionQuality: quality), data.count < maxSize  {
            print("Giữ nguyên kích thước ảnh")
            return data
        }
        
        while quality > 0 {
            quality -= step
            if let data = self.jpegData(compressionQuality: quality), data.count < maxSize {
                print("Data hợp lệ: \(quality) percent")
                return data
            }
        }
        return nil
    }
}

#endif
