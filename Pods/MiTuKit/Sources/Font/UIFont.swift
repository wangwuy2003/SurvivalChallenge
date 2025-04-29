//
//  UIFont.swift
//  MiTuKit
//
//  Created by Admin on 28/2/25.
//

import UIKit

public extension UIFont {
    private static let FNames = FontConfiguration.shared
    
    static func bold(_ size: CGFloat = 20) -> UIFont {
        return UIFont(name: FNames.bold, size: size) ?? UIFont.boldSystemFont(ofSize: size)
    }
    
    static func regular(_ size: CGFloat = 17) -> UIFont {
        return UIFont(name: FNames.regular, size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    static func boldItalic(_ size: CGFloat = 20) -> UIFont {
        guard let font = UIFont(name: FNames.boldItalic, size: size) else {
            let font = UIFont.systemFont(ofSize: size, weight: .regular)
            let descriptor = font.fontDescriptor.withSymbolicTraits([.traitBold, .traitItalic])
            return UIFont(descriptor: descriptor ?? font.fontDescriptor, size: size)
        }
        
        return  font
    }
    
    static func black(_ size: CGFloat = 20) -> UIFont {
        return UIFont(name: FNames.black, size: size) ?? UIFont.systemFont(ofSize: size, weight: .black)
    }
    
    static func medium(_ size: CGFloat = 18) -> UIFont {
        return UIFont(name: FNames.medium, size: size) ?? UIFont.systemFont(ofSize: size, weight: .medium)
    }
    
    static func semiBold(_ size: CGFloat = 18) -> UIFont {
        return UIFont(name: FNames.semiBold, size: size) ?? UIFont.systemFont(ofSize: size, weight: .semibold)
    }
    
    static func thin(_ size: CGFloat = 17) -> UIFont {
        return UIFont(name: FNames.thin, size: size) ?? UIFont.systemFont(ofSize: size, weight: .thin)
    }
    
    static func ultralight(_ size: CGFloat = 17) -> UIFont {
        return UIFont(name: FNames.ultralight, size: size) ?? UIFont.systemFont(ofSize: size, weight: .ultraLight)
    }
    
    static func regularItalic(_ size: CGFloat = 17) -> UIFont {
        return UIFont(name: FNames.regularItalic, size: size) ?? UIFont.italicSystemFont(ofSize: size)
    }
}

public class FontConfiguration {
    public static let shared = FontConfiguration()
    
    public func update(regular: String? = nil, regularItalic: String? = nil, ultralight: String? = nil, thin: String? = nil, light: String? = nil, medium: String? = nil, semiBold: String? = nil, bold: String? = nil, boldItalic: String? = nil, black: String? = nil) {
        
        if let regular = regular { self.regular = regular }
        if let regularItalic = regularItalic { self.regularItalic = regularItalic }
        if let ultralight = ultralight { self.ultralight = ultralight }
        if let thin = thin { self.thin = thin }
        if let light = light { self.light = light }
        if let medium = medium { self.medium = medium }
        if let semiBold = semiBold { self.semiBold = semiBold }
        if let bold = bold { self.bold = bold }
        if let boldItalic = boldItalic { self.boldItalic = boldItalic }
        if let black = black { self.black = black }
    }
    
    
    public var regular = "SFProText-Regular"
    public var regularItalic = "SFProText-RegularItalic"
    public var ultralight = "SFProText-Ultralight"
    public var thin = "SFProText-Thin"
    public var light = "SFProText-Light"
    public var medium = "SFProText-Medium"
    public var semiBold = "SFProText-Semibold"
    public var bold = "SFProText-Bold"
    public var boldItalic = "SFProText-BoldItalic"
    public var black = "SFProText-Black"
}
