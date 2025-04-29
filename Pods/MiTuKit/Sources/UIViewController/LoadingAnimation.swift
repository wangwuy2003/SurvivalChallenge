//
//  LoadingAnimation.swift
//  MiTuKit
//
//  Created by Hồ Minh Tường on 21/11/21.
//  Copyright © 2021 - Present MiTu Ultra

#if os(iOS)
import Foundation
import UIKit

public extension UIViewController {
    func showLoading(color: UIColor = UIColor.purple, style: UIActivityIndicatorView.Style = .large, backgroundColor: UIColor = .clear, containerColor: UIColor = .clear, containerRadius: CGFloat = 8, containerWidth: CGFloat = 66) {
        Queue.main {
            Task(priority: .high) {
                await self._hideLoading()
                await self._showLoading(color: color, style: style, backgroundColor: backgroundColor, containerColor: containerColor, containerRadius: containerRadius, containerWidth: containerWidth)
            }
        }
    }
    
    func hideLoading() {
        Queue.main {
            Task(priority: .high) {
                await self._hideLoading()
            }
        }
    }
    
    private func _hideLoading() async -> Void {
        self.view.subviews.filter{$0 is IndicatorView}.forEach {
            guard let indicatorView = $0 as? IndicatorView else {
                return
            }
            indicatorView.stopAnimating()
            indicatorView.removeFromSuperview()
        }
    }
    
    private func _showLoading(color: UIColor = UIColor.purple, style: UIActivityIndicatorView.Style = .large, backgroundColor: UIColor = .clear, containerColor: UIColor = .clear, containerRadius: CGFloat = 8, containerWidth: CGFloat = 66) async -> Void {
        let indicatorView = IndicatorView()
        indicatorView >>> self.view >>> {
            $0.snp.makeConstraints {
                $0.top.leading.trailing.bottom.equalToSuperview()
            }
            $0.backgroundColor = backgroundColor
            $0.containerColor = containerColor
            $0.containerRadius = containerRadius
            $0.containerWidth = containerWidth
            $0.style = style
            $0.color = color
            $0.startAnimating()
        }
        self.view.bringSubviewToFront(indicatorView)
    }
}

open class IndicatorView: UIView {
    public let indicatorView = UIActivityIndicatorView()
    public let containerView = UIView()
    
    public var style: UIActivityIndicatorView.Style = .large {
        didSet {
            self.indicatorView.style = style
        }
    }
    
    public var color: UIColor = UIColor.systemBlue {
        didSet {
            self.indicatorView.color = color
        }
    }
    
    public var containerColor: UIColor = UIColor.clear {
        didSet {
            self.containerView.backgroundColor = containerColor
        }
    }
    
    public var containerRadius: CGFloat = 0 {
        didSet {
            self.containerView.layer.masksToBounds = true
            self.containerView.layer.cornerRadius = containerRadius
        }
    }
    
    public var containerWidth: CGFloat = 66 {
        didSet {
            self.containerView.snp.updateConstraints {
                $0.width.height.equalTo(containerWidth)
            }
            self.layoutIfNeeded()
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupView()
    }
    
    private func setupView() {
        backgroundColor = .clear
        
        containerView >>> self >>> {
            $0.snp.makeConstraints {
                $0.center.equalToSuperview()
                $0.width.height.equalTo(66)
            }
            $0.backgroundColor = .clear
        }
        
        indicatorView >>> containerView >>> {
            $0.snp.makeConstraints {
                $0.center.equalToSuperview()
                $0.width.height.equalTo(50)
            }
            $0.hidesWhenStopped = true
        }
    }
}

public extension IndicatorView {
    func startAnimating() {
        self.indicatorView.isHidden = false
        self.indicatorView.isUserInteractionEnabled = true
        self.indicatorView.startAnimating()
    }
    
    func stopAnimating() {
        self.indicatorView.isHidden = true
        self.indicatorView.isUserInteractionEnabled = false
        self.indicatorView.stopAnimating()
    }
}

#endif
