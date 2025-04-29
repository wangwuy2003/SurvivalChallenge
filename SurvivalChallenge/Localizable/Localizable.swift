//
//  Localizable.swift
//  Magnifier Magnifying Glass 10x
//
//  Created by Pham Van Thai on 28/07/2023.
//

import Foundation
import UIKit

class Localizable {
    class func localizedString(_ key: String, comment: String = "") -> String {
        return NSLocalizedString(key, comment: comment)
    }
    class func localizedString(_ key: String, withValue value: Int, comment: String = "") -> String {
        // Lấy chuỗi từ Localizable.strings với placeholder
        let localizedString = NSLocalizedString(key, comment: comment)
        // Thay thế placeholder với giá trị
        return String(format: localizedString, value)
    }
}
