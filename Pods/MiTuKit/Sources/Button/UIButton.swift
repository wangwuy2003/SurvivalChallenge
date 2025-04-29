//
//  UIButton.swift
//  Pods
//
//  Created by Admin on 28/2/25.
//

import UIKit

public extension UIButton {
    var font: UIFont? {
        get {
            return titleLabel?.font
        }
        set {
            titleLabel?.font = newValue
        }
    }
}
