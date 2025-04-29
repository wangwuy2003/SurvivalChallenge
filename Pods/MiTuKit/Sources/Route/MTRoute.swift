//
//  MTRoute.swift
//  MiTuKit
//
//  Created by Hồ Minh Tường on 21/11/21.
//  Copyright © 2021 - Present MiTu Ultra

#if os(iOS)
import Foundation
import UIKit

public func setupWindow(viewcontroller: UIViewController, navigate: Bool = true, options: UIView.AnimationOptions = []) -> UIWindow {
    let window = UIWindow(frame: UIScreen.main.bounds)
    let rootViewController = navigate ? UINavigationController(rootViewController: viewcontroller) : viewcontroller
    window.rootViewController = rootViewController
    window.makeKeyAndVisible()
    if !options.isEmpty {
        UIView.transition(with: window, duration: 0.3, options: options, animations: {}, completion: nil)
    }
    return window
}

public func setRootView(viewcontroller: UIViewController, window: UIWindow, navigate: Bool = true, options: UIView.AnimationOptions = [], duration: TimeInterval = 0.3, completion: ((Bool) -> Void)? = nil) {
    let rootViewController = navigate ? UINavigationController(rootViewController: viewcontroller) : viewcontroller
    window.rootViewController = rootViewController
    window.makeKeyAndVisible()
    if !options.isEmpty {
        UIView.transition(with: window, duration: duration, options: options, animations: {}, completion: completion)
    }
}

#endif
