//
//  MTView.swift
//  MiTuKit
//
//  Created by Hồ Minh Tường on 21/11/21.
//  Copyright © 2021 - Present MiTu Ultra

#if os(iOS)
import UIKit

public extension UIView {
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
    
    func addDropShadow(color: UIColor = UIColor.black, shadowOpacity: Float = 1, shadowOffset: CGSize = .zero, shadowRadius: CGFloat = 20) {
        layer.masksToBounds = false
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = shadowOpacity
        layer.shadowOffset = shadowOffset
        layer.shadowRadius = shadowRadius
    }
}


public extension UIView {
    func asImage() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}


public extension UIView {
    func disable(alpha: CGFloat = 0.5) {
        self.alpha = alpha
        self.isUserInteractionEnabled = false
    }
    
    func enable() {
        self.alpha = 1.0
        self.isUserInteractionEnabled = true
    }
}


public extension  UIView {
    func fadeIn(duration: TimeInterval = 0.5, delay: TimeInterval = 0.0, options: UIView.AnimationOptions = .curveEaseIn) {
        UIView.animate(withDuration: duration, delay: delay, options: options, animations: {
            self.alpha = 1.0
        }, completion: {_ in self.isHidden = false })
    }
    
    func fadeOut(duration: TimeInterval = 0.5, delay: TimeInterval = 0.0, options: UIView.AnimationOptions = .curveEaseIn, hidden: Bool = false) {
        UIView.animate(withDuration: duration, delay: delay, options: options, animations: {
            self.alpha = 0.0
        }, completion: {_ in self.isHidden = hidden})
    }
    
    func shake(_ count: Float = 0.0, direction: Direction = .vertical) {
        layer.removeAllAnimations()
        
        let keypath = direction == .vertical ? "transform.translation.y" : "transform.translation.x"
        let animation = CAKeyframeAnimation(keyPath: keypath)
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.duration = 0.6
        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0 ]
        animation.repeatCount = count
        layer.add(animation, forKey: "shake")
    }
    
    enum Direction {
        case horizontal
        case vertical
    }
}

public extension UIView {
    func tapHandle(_ closure: @escaping ()->()) {
        let sleeve = ClosureSleeve(closure)
        let tapGesture = UITapGestureRecognizer(target: sleeve, action: #selector(ClosureSleeve.invoke))
        self.addGestureRecognizer(tapGesture)
        objc_setAssociatedObject(self, "[\(arc4random())]", sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
}

public extension UIView {
    private static var _maxScale: CGFloat = 10.0
    private static var _minScale: CGFloat = 1.0
    
    var maxScale: CGFloat {
        get {
            return UIView._maxScale
        }
        set {
            UIView._maxScale = newValue
        }
    }
    
    var minScale: CGFloat {
        get {
            return UIView._minScale
        }
        set {
            UIView._minScale = newValue
        }
    }
    
    func removeAllGestureRecognizers() {
        if let gestures = gestureRecognizers {
            for gesture in gestures {
                self.removeGestureRecognizer(gesture)
            }
        }
    }
    
    func addZooming() {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinch(_:)))
        self.addGestureRecognizer(pinch)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(resetTransform))
        tap.numberOfTapsRequired = 2
        self.addGestureRecognizer(tap)
    }
    
    func addRotate() {
        let rotate = UIRotationGestureRecognizer(target: self, action: #selector(rotate(_:)))
        self.addGestureRecognizer(rotate)
    }
    
    @objc func resetTransform() {
        self.transform = CGAffineTransform.identity
    }
    
    @objc func pan(_ sender: UIPanGestureRecognizer) {
        guard let targetView = sender.view else {return}
        let translation = sender.translation(in: self.superview)
        targetView.center = CGPoint(x: targetView.center.x + translation.x, y: targetView.center.y + translation.y)
        sender.setTranslation(.zero, in: self.superview)
    }
    
    @objc func pinch(_ sender: UIPinchGestureRecognizer) {
        let currentScale = self.frame.width/self.bounds.size.width
        var newScale = sender.scale
        if currentScale * sender.scale < minScale {
            newScale = minScale / currentScale
        } else if currentScale * sender.scale > maxScale {
            newScale = maxScale / currentScale
        }
        self.transform = self.transform.scaledBy(x: newScale, y: newScale)
        sender.scale = 1
        
    }
    
    @objc func rotate(_ sender: UIRotationGestureRecognizer) {
        guard let targetView = sender.view else {return}
        targetView.transform = targetView.transform.rotated(by: sender.rotation)
        sender.rotation = 0
    }
}

public extension UIView {
    func rotate(withDuration duration: Double = 0.3, angle: CGFloat = CGFloat.pi) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: duration, animations: {
                self.self.transform = self.self.transform.rotated(by: angle)
            })
        }
    }
    
    func revealTransform(withDuration duration: Double = 0.3) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: duration, animations: {
                self.self.transform = .identity
            })
        }
    }
}

public extension UIView {
    static func animateStatus(duration: Double, animations: @escaping () -> Void) async -> Bool {
        return await withCheckedContinuation { continuation in
            UIView.animate(withDuration: duration, animations: animations, completion: { status in
                continuation.resume(returning: status)
            })
        }
    }
    
    static func animate(duration: Double, animations: @escaping () -> Void) async -> Void {
        return await withCheckedContinuation { continuation in
            UIView.animate(withDuration: duration, animations: animations, completion: { status in
                continuation.resume()
            })
        }
    }
}
#endif
