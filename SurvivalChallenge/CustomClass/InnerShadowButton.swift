//
//  InnerShadowButton.swift
//  SurvivalChallenge
//
//  Created by Apple on 17/4/25.
//

import CoreGraphics
import UIKit

struct InnerShadow {
    var color: UIColor
    var offset: CGSize
    var blur: CGFloat
}
 
class InnerShadowButton: UIButton {
 
    var shadows: [InnerShadow] = [
        InnerShadow(color: UIColor(white: 1.0, alpha: 0.25), offset: CGSize(width: 0, height: 2), blur: 4)
    ]
 
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }
 
        let bounds = self.bounds
        let cornerRadius = self.layer.cornerRadius
        let insetRect = bounds.insetBy(dx: 0, dy: 0)
 
        let visiblePath = UIBezierPath(roundedRect: insetRect, cornerRadius: cornerRadius).cgPath
        context.addPath(visiblePath)
        context.setFillColor(self.backgroundColor?.cgColor ?? UIColor.white.cgColor)
        context.fillPath()
 
        context.saveGState()
        context.addPath(visiblePath)
        context.clip()
 
        for shadow in shadows {
            // Create outer rect and subtract visible path
            let outerPath = CGMutablePath()
            outerPath.addRect(bounds.insetBy(dx: -42, dy: -42))
            outerPath.addPath(visiblePath)
 
            context.saveGState()
            context.setShadow(offset: shadow.offset, blur: shadow.blur, color: shadow.color.cgColor)
            context.addPath(outerPath)
            context.setFillColor(shadow.color.cgColor)
            context.drawPath(using: .eoFill)
            context.restoreGState()
        }
 
        context.restoreGState()
    }
}
