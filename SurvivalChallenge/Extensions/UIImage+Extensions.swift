

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
    
//    func fillWhiteAreas(with color: UIColor) -> UIImage? {
//        // Chuyển đổi UIImage sang CGImage
//        guard let cgImage = self.cgImage else { return nil }
//        
//        let width = cgImage.width
//        let height = cgImage.height
//        let colorSpace = CGColorSpaceCreateDeviceRGB()
//        let bytesPerPixel = 4
//        let bytesPerRow = bytesPerPixel * width
//        let bitsPerComponent = 8
//        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
//        
//        // Tạo context để vẽ
//        guard let context = CGContext(data: nil,
//                                      width: width,
//                                      height: height,
//                                      bitsPerComponent: bitsPerComponent,
//                                      bytesPerRow: bytesPerRow,
//                                      space: colorSpace,
//                                      bitmapInfo: bitmapInfo) else { return nil }
//        
//        // Vẽ hình ảnh gốc vào context
//        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
//        
//        // Lấy dữ liệu pixel
//        guard let pixelData = context.data else { return nil }
//        let data = pixelData.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)
//        
//        // Lấy các thành phần màu thay thế
//        let components = color.cgColor.components ?? [1, 0, 0, 1] // Mặc định là đỏ nếu thất bại
//        let r = UInt8(components[0] * 255)
//        let g = UInt8(components[1] * 255)
//        let b = UInt8(components[2] * 255)
//        let a = UInt8(components[3] * 255)
//        
//        // Duyệt qua từng pixel và thay đổi màu nếu cần
//        for y in 0..<height {
//            for x in 0..<width {
//                let pixelIndex = (width * y + x) * bytesPerPixel
//                let red = data[pixelIndex]
//                let green = data[pixelIndex + 1]
//                let blue = data[pixelIndex + 2]
//                let alpha = data[pixelIndex + 3]
//                
//                // Kiểm tra pixel gần trắng
//                if red > 200 && green > 200 && blue > 200 && alpha > 0 {
//                    data[pixelIndex] = r
//                    data[pixelIndex + 1] = g
//                    data[pixelIndex + 2] = b
//                    data[pixelIndex + 3] = a
//                }
//            }
//        }
//        
//        // Tạo và trả về hình ảnh mới
//        guard let newCGImage = context.makeImage() else { return nil }
//        return UIImage(cgImage: newCGImage)
//    }
    
    func fillWhiteAreas(with color: UIColor) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        
        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        
        guard let context = CGContext(data: nil,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: bitsPerComponent,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo) else { return nil }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let pixelData = context.data else { return nil }
        let data = pixelData.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)
        
        let components = color.cgColor.components ?? [1, 1, 1, 1]
        let r = UInt8(components[0] * 255)
        let g = UInt8(components[1] * 255)
        let b = UInt8(components[2] * 255)
        let a = UInt8(components[3] * 255)
        
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = (width * y + x) * bytesPerPixel
                
                let red = data[pixelIndex]
                let green = data[pixelIndex + 1]
                let blue = data[pixelIndex + 2]
                let alpha = data[pixelIndex + 3]
                
                // Kiểm tra pixel có phải là màu trắng (hoặc gần trắng) và có alpha > 0
                if red > 200 && green > 200 && blue > 200 && alpha > 0 {
                    data[pixelIndex] = r
                    data[pixelIndex + 1] = g
                    data[pixelIndex + 2] = b
                    data[pixelIndex + 3] = a
                }
            }
        }
        
        guard let newCGImage = context.makeImage() else { return nil }
        return UIImage(cgImage: newCGImage)
    }
}
