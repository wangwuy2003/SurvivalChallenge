//
//  UILabel.swift
//  MiTuKit
//
//  Created by Hồ Minh Tường on 21/11/21.
//  Copyright © 2021 - Present MiTu Ultra

#if os(iOS)
import UIKit

public extension UILabel {
    func optimisedFont(fontName: String, minSize: CGFloat, maxSize: CGFloat) {
        let text: String = self.text ?? ""
        var tempFont: UIFont
        var tempMax: CGFloat = maxSize
        var tempMin: CGFloat = minSize

        while (ceil(tempMin) != ceil(tempMax)){
            let testedSize = (tempMax + tempMin) / 2


            tempFont = UIFont(name: fontName, size:testedSize)!
            let attributedString = NSAttributedString(string: text, attributes: [NSAttributedString.Key.font : tempFont])

            let textFrame = attributedString.boundingRect(with: CGSize(width: self.bounds.size.width, height: CGFloat.greatestFiniteMagnitude), options: NSStringDrawingOptions.usesLineFragmentOrigin , context: nil)

            let difference = self.frame.height - textFrame.height
            
            if(difference > 0) {
                tempMin = testedSize
            }else{
                tempMax = testedSize
            }
        }
        self.font = UIFont(name: fontName, size: tempMin - 1)!
    }
    
    
}

public extension UILabel {
    func set(text: String, icon: UIImage? = nil, attributeString: NSMutableAttributedString? = nil, imageSize: CGSize = CGSize(width: 25, height: 25)) {
        
        let fullString = NSMutableAttributedString(string: text)

        if let image = icon {
            fullString.append(NSAttributedString(string: " "))
            
            let image1Attachment = NSTextAttachment()
            image1Attachment.image = image
            image1Attachment.bounds = CGRect(x: 0, y: -8, width: imageSize.width, height: imageSize.height)
            let image1String = NSAttributedString(attachment: image1Attachment)
            fullString.append(image1String)
        }
        
        if let rightText = attributeString {
            fullString.append(NSAttributedString(string: " "))
            fullString.append(rightText)
        }
        
        self.attributedText = fullString
    }
    
    func set(leftAttributeString: NSMutableAttributedString, icon: UIImage? = nil, rightAttributeString: NSMutableAttributedString? = nil, imageSize: CGSize = CGSize(width: 25, height: 25)) {
        
        let fullString = leftAttributeString

        if let image = icon {
            fullString.append(NSAttributedString(string: " "))
            
            let image1Attachment = NSTextAttachment()
            image1Attachment.image = image
            image1Attachment.bounds = CGRect(x: 0, y: -8, width: imageSize.width, height: imageSize.height)
            let image1String = NSAttributedString(attachment: image1Attachment)
            fullString.append(image1String)
        }
        
        if let rightText = rightAttributeString {
            fullString.append(NSAttributedString(string: " "))
            fullString.append(rightText)
        }
        
        self.attributedText = fullString
    }
    
    func set(leftAttributeString: NSMutableAttributedString, icon: UIImage? = nil, rightText: String? = nil, imageSize: CGSize = CGSize(width: 25, height: 25)) {
        
        let fullString = leftAttributeString

        if let image = icon {
            fullString.append(NSAttributedString(string: " "))
            
            let image1Attachment = NSTextAttachment()
            image1Attachment.image = image
            image1Attachment.bounds = CGRect(x: 0, y: -8, width: imageSize.width, height: imageSize.height)
            let image1String = NSAttributedString(attachment: image1Attachment)
            fullString.append(image1String)
        }
        
        if let rightText = rightText {
            fullString.append(NSAttributedString(string: " "))
            fullString.append(NSAttributedString(string: rightText))
        }
        
        self.attributedText = fullString
    }
}

#endif
