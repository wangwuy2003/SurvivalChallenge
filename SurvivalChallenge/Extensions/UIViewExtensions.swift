

import UIKit


@IBDesignable
extension UIView {
    var screenWidth: CGFloat {
        return UIScreen.main.bounds.width
    }
        
    var screenHeight: CGFloat {
        return UIScreen.main.bounds.height
    }
    
    func applyGradient(
            colours: [UIColor],
            cornerRadius: CGFloat? = nil,
            startPoint: CGPoint,
            endPoint: CGPoint,
            applyToText: Bool = false,
            strokeWidth: CGFloat? = nil,
            strokeColor: UIColor? = nil
    ) {
        // Xóa gradient layer cũ
        layer.sublayers?.filter { $0 is CAGradientLayer }.forEach { $0.removeFromSuperlayer() }
        
        // Tạo gradient layer
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = self.bounds
        if let cornerRadius = cornerRadius {
            gradient.cornerRadius = cornerRadius
        }
        gradient.startPoint = startPoint
        gradient.endPoint = endPoint
        gradient.colors = colours.map { $0.cgColor }
        
        if applyToText, let label = self as? UILabel {
            // Áp dụng gradient cho văn bản của UILabel
            let attributedString = NSMutableAttributedString(string: label.text ?? "")
            var attributes: [NSAttributedString.Key: Any] = [:]
            
            // Thêm viền nếu có
            if let strokeWidth = strokeWidth, let strokeColor = strokeColor {
                attributes[.strokeWidth] = -strokeWidth
                attributes[.strokeColor] = strokeColor
                attributes[.foregroundColor] = UIColor.clear
            }
            
            attributedString.addAttributes(attributes, range: NSRange(location: 0, length: attributedString.length))
            label.attributedText = attributedString
            
            let textLayer = CALayer()
            textLayer.frame = label.bounds
            textLayer.contents = label.attributedText?.createImage(from: label.bounds.size)?.cgImage
            
            gradient.mask = textLayer
            label.layer.addSublayer(gradient)
        } else {
            self.layer.insertSublayer(gradient, at: 0)
        }
    }
    
    func dropShadow(scale: Bool = true) {
      layer.masksToBounds = false
      layer.shadowColor = UIColor.black.cgColor
      layer.shadowOpacity = 0.5
      layer.shadowOffset = CGSize(width: -1, height: 1)
      layer.shadowRadius = 1

      layer.shadowPath = UIBezierPath(rect: bounds).cgPath
      layer.shouldRasterize = true
      layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }

    // OUTPUT 2
    func dropShadow(color: UIColor, opacity: Float = 0.5, offSet: CGSize, radius: CGFloat = 1, scale: Bool = true) {
      layer.masksToBounds = false
      layer.shadowColor = color.cgColor
      layer.shadowOpacity = opacity
      layer.shadowOffset = offSet
      layer.shadowRadius = radius

      layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
      layer.shouldRasterize = true
      layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
    
    func setCornerRadius(_ cornerRadius: CGFloat) {
        self.layer.cornerRadius = cornerRadius
        self.layer.masksToBounds = true
    }
    
    func toImage() -> UIImage? {
        var image: UIImage?
        DispatchQueue.main.sync {
            UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.main.scale)
            defer { UIGraphicsEndImageContext() }
            if let context = UIGraphicsGetCurrentContext() {
                self.layer.render(in: context)
                image = UIGraphicsGetImageFromCurrentImageContext()
            }
        }
        return image
    }
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        get {
            guard let borderColor = layer.borderColor else {
                return nil
            }
            return UIColor(cgColor: borderColor)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
}

extension NSAttributedString {
    func createImage(from size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        let rect = CGRect(origin: .zero, size: size)
        self.draw(in: rect)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}


