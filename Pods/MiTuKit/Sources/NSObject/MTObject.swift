//
//  MTObject.swift
//  MiTuKit
//
//  Created by Hồ Minh Tường on 21/11/21.
//  Copyright © 2021 - Present MiTu Ultra

#if os(iOS)
import Foundation

public extension NSObject {
    @nonobjc class var className: String {
        return String(describing: self)
    }
    
    var className: String {
        return type(of: self).className
    }
}
#endif
