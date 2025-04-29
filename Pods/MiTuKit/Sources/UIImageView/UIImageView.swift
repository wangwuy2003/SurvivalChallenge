//
//  UIImageView.swift
//  MiTuKit
//
//  Created by Hồ Minh Tường on 21/11/21.
//  Copyright © 2021 - Present MiTu Ultra

#if os(iOS)
import UIKit

public extension UIImageView {
    func setImage(_ image: UIImage?, options: UIView.AnimationOptions? = nil, completion: (() -> Void)? = nil) {
        Queue.main {
            if let options = options {
                UIView.transition(with: self,
                                  duration: 0.25,
                                  options: options,
                                  animations: { self.image = image},
                                  completion: { _ in
                                completion?()
                })
            } else {
                self.image = image
                completion?()
            }
        }
    }
}

#endif


