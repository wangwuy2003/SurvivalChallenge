//
//  MTApplication.swift
//  MiTuKit
//
//  Created by Hồ Minh Tường on 21/11/21.
//  Copyright © 2021 - Present MiTu Ultra

#if os(iOS)
import Foundation
import UIKit

public extension UIApplication {
    //Opens Settings app
    func openSettingsApp(completion: ((Bool) -> Void)? = nil) {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: completion)
    }
}

#endif
