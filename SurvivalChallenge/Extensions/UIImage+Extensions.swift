

import Foundation
import UIKit

extension UIImage {
    convenience init?(pixelBuffer: CVPixelBuffer) {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        self.init(cgImage: cgImage)
    }
    
    static func gradientImage(bounds: CGRect, colors: [UIColor]) -> UIImage {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = colors.map(\.cgColor)
        // This makes it left to right, default is top to bottom
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        
        return renderer.image { ctx in
            gradientLayer.render(in: ctx.cgContext)
        }
    }
    
    func resize(toSize newWidth: CGFloat) -> UIImage? {
        let scale = newWidth / size.width
        let newHeight = size.height * scale
        var width = 720
        var height = 1280
        var offset: CGFloat = -100
        if Utils.isIpad() {
            width = 1080
            height = 1920
            offset = 200
        }
        UIGraphicsBeginImageContext(CGSize(width: width, height: height))
        draw(in: CGRect(x: 0, y: offset, width: newWidth, height: newHeight))
        guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return newImage
    }

    func resize(to newSize: CGSize) -> UIImage? {
        // Bắt đầu tạo một bitmap-based graphics context
        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        // Vẽ ảnh vào context với kích thước mới
        self.draw(in: CGRect(origin: .zero, size: newSize))
        // Lấy ảnh mới từ context
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        // Kết thúc context
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
    func resizeWithFixedWidth(_ width: CGFloat) -> (UIImage?, CGFloat) {
        // Tính toán tỷ lệ khung hình của ảnh gốc
        let aspectRatio = self.size.height / self.size.width
        
        // Tính toán chiều cao mới dựa trên chiều rộng cố định và tỷ lệ khung hình
        let newHeight = width * aspectRatio
        let newSize = CGSize(width: width, height: newHeight)
        
        // Bắt đầu tạo một bitmap-based graphics context
        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        // Vẽ ảnh vào context với kích thước mới
        self.draw(in: CGRect(origin: .zero, size: newSize))
        // Lấy ảnh mới từ context
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        // Kết thúc context
        UIGraphicsEndImageContext()
        return (resizedImage, newHeight)
    }
    
    func resizeWithFixedHeight(_ height: CGFloat) -> (UIImage?, CGFloat) {
        // Tính toán tỷ lệ khung hình của ảnh gốc
        let aspectRatio = self.size.width / self.size.height
        
        // Tính toán chiều rộng mới dựa trên chiều cao cố định và tỷ lệ khung hình
        let newWidth = height * aspectRatio
        let newSize = CGSize(width: newWidth, height: height)
        
        // Bắt đầu tạo một bitmap-based graphics context
        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        // Vẽ ảnh vào context với kích thước mới
        self.draw(in: CGRect(origin: .zero, size: newSize))
        // Lấy ảnh mới từ context
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        // Kết thúc context
        UIGraphicsEndImageContext()
        
        return (resizedImage, newWidth)
    }

    
}
