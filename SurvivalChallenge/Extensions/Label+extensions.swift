

import Foundation
import UIKit

extension NSMutableAttributedString {
    func setAsLink(textToFind:String, linkName:String) {
        let foundRange = self.mutableString.range(of: textToFind)
        if foundRange.location != NSNotFound {
            self.addAttribute(NSAttributedString.Key.link, value: linkName, range: foundRange)
        }
    }
}

extension UIFont {
    static func rowdiesBold(ofSize size: CGFloat) -> UIFont {
        return UIFont(name: "Rowdies Bold", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    static func rowdiesLight(ofSize size: CGFloat) -> UIFont {
        return UIFont(name: "Rowdies Light", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    static func rowdiesRegular(ofSize size: CGFloat) -> UIFont {
        return UIFont(name: "Rowdies Regular", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    static func sfProDisplayRegular(ofSize size: CGFloat) -> UIFont {
        return UIFont(name: "SFProDisplay-Regular", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    static func sfProDisplayMedium(ofSize size: CGFloat) -> UIFont {
        return UIFont(name: "SFProDisplay-Medium", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    static func sfProDisplayBold(ofSize size: CGFloat) -> UIFont {
        return UIFont(name: "SFProDisplay-Bold", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    static func luckiestGuyRegular(ofSize size: CGFloat) -> UIFont {
        return UIFont(name: "LuckiestGuy-Regular", size: size) ?? UIFont.systemFont(ofSize: size)
    }
}

extension UILabel {
    func applyGradientWith(
            startColor: UIColor,
            endColor: UIColor,
            direction: GradientDirection = .leftToRight
    ) -> Bool {
        // Trích xuất màu
        var startColorRed: CGFloat = 0
        var startColorGreen: CGFloat = 0
        var startColorBlue: CGFloat = 0
        var startAlpha: CGFloat = 0
        
        if !startColor.getRed(&startColorRed, green: &startColorGreen, blue: &startColorBlue, alpha: &startAlpha) {
            return false
        }
        
        var endColorRed: CGFloat = 0
        var endColorGreen: CGFloat = 0
        var endColorBlue: CGFloat = 0
        var endAlpha: CGFloat = 0
        
        if !endColor.getRed(&endColorRed, green: &endColorGreen, blue: &endColorBlue, alpha: &endAlpha) {
            return false
        }
        
        // Tạo gradient cho văn bản
        let gradientText = self.text ?? ""
        
        // Tính kích thước văn bản
        let attributes: [NSAttributedString.Key: Any] = [
            .font: self.font ?? UIFont.systemFont(ofSize: 17)
        ]
        let textSize = gradientText.size(withAttributes: attributes)
        let width: CGFloat = textSize.width
        let height: CGFloat = textSize.height
        
        // Đảm bảo kích thước hợp lệ
        guard width > 0, height > 0 else { return false }
        
        // Tạo context để vẽ gradient
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return false
        }
        
        UIGraphicsPushContext(context)
        
        // Tạo gradient
        let rgbColorspace = CGColorSpaceCreateDeviceRGB()
        let locations: [CGFloat] = [0.0, 1.0]
        let components: [CGFloat] = [
            startColorRed, startColorGreen, startColorBlue, startAlpha,
            endColorRed, endColorGreen, endColorBlue, endAlpha
        ]
        guard let glossGradient = CGGradient(colorSpace: rgbColorspace, colorComponents: components, locations: locations, count: 2) else {
            UIGraphicsPopContext()
            return false
        }
        
        // Đặt hướng gradient
        let startPoint: CGPoint
        let endPoint: CGPoint
        switch direction {
        case .leftToRight:
            startPoint = CGPoint(x: 0, y: height / 2)
            endPoint = CGPoint(x: width, y: height / 2)
        case .topToBottom:
            startPoint = CGPoint.zero
            endPoint = CGPoint(x: 0, y: height)
        case .rightToLeft:
            startPoint = CGPoint(x: width, y: height / 2)
            endPoint = CGPoint(x: 0, y: height / 2)
        case .bottomToTop:
            startPoint = CGPoint(x: 0, y: height)
            endPoint = CGPoint.zero
        }
        
        // Vẽ gradient
        context.drawLinearGradient(
            glossGradient,
            start: startPoint,
            end: endPoint,
            options: .drawsBeforeStartLocation
        )
        
        UIGraphicsPopContext()
        
        guard let gradientImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return false
        }
        
        // Áp dụng gradient cho văn bản
        self.textColor = UIColor(patternImage: gradientImage)
        
        return true
    }
}

// Enum để định nghĩa hướng gradient
enum GradientDirection {
    case leftToRight
    case rightToLeft
    case topToBottom
    case bottomToTop
}
