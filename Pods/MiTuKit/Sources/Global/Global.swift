//
//  Global.swift
//  MiTuKit
//
//  Created by Hồ Minh Tường on 21/11/21.
//  Copyright © 2021 - Present MiTu Ultra

//MARK: - UISCREEN
#if os(iOS)
import UIKit

public var screenSize: CGSize {
    return UIScreen.main.bounds.size
}

public var maxWidth: CGFloat {
    return UIScreen.main.bounds.width
}

public var maxHeight: CGFloat {
    return UIScreen.main.bounds.height
}

public func currentWindow() -> UIWindow? {
    return (UIApplication.shared.connectedScenes.first?.delegate as? UIWindowSceneDelegate)?.window ?? UIApplication.shared.windows.first
}

public var topSafeHeight: CGFloat {
    if let window = currentWindow() {
        return window.safeAreaInsets.top
    }
    return 0
}

public var botSafeHeight: CGFloat {
    if let window = currentWindow() {
        return window.safeAreaInsets.bottom
    }
    return 0
}

public var leftSafeHeight: CGFloat {
    if let window = currentWindow() {
        return window.safeAreaInsets.left
    }
    return 0
}

public var rightSafeHeight: CGFloat {
    if let window = currentWindow() {
        return window.safeAreaInsets.right
    }
    return 0
}

public var topViewController: UIViewController? {
    let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
    if var topController = keyWindow?.rootViewController {
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        return topController
    }
    return nil
}

public func animateView(duration: Double, animations: @escaping () -> Void) async -> Void {
    return await withCheckedContinuation { continuation in
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.39, animations: animations, completion: { status in
                continuation.resume()
            })
        }
    }
}

public func delay(_ duration: Double) async -> Void {
    return await withCheckedContinuation { continuation in
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: {
            continuation.resume()
        })
    }
}

#endif
