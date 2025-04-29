//
//  MTProgressView.swift
//  MiTuKit
//
//  Created by Hồ Minh Tường on 21/11/21.
//  Copyright © 2021 - Present MiTu Ultra

#if os(iOS)
import UIKit

public class MTProgressView: UIView {
    public init() {
        super.init(frame: .zero)
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    //MARK: Variables
    public let indicatorView = UIActivityIndicatorView()
    public let loadingLabel = LoadingLabel()
    public let progressView = UIProgressView()
    
    public var loadingString: String = "Loading" {
        didSet {
            self.loadingLabel.text = self.loadingString
        }
    }
    
    public var progress: Float = 0 {
        didSet {
            self.updateProgress(progress)
        }
    }
    
    public var progressTintColor: UIColor = .blue {
        didSet {
            self.progressView.progressTintColor = progressTintColor
        }
    }
    
    public override var backgroundColor: UIColor? {
        didSet {
            self.progressView.backgroundColor = backgroundColor
        }
    }
    
    public var isLoading: Bool {
        return self.indicatorView.isAnimating && self.loadingLabel.isLoading
    }
    
}

public extension MTProgressView {
    func stopAnimating() {
        self.loadingLabel.stopAnimating()
        self.indicatorView.stopAnimating()
    }
    
    func startAnimating() {
        self.loadingLabel.startAnimating()
        self.indicatorView.startAnimating()
    }
    
    func updateProgress(_ progress: Float) {
        if !isLoading {
            self.startAnimating()
        }
        
        if progress < 0 {
            self.progressView.setProgress(0, animated: false)
        } else if progress > 1 {
            self.progressView.setProgress(1, animated: false)
        } else {
            self.progressView.setProgress(progress, animated: true)
        }
    }
    
    private func setupView() {
        self.backgroundColor = .clear
        
        progressView >>> self >>> {
            $0.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
            $0.progressTintColor = self.progressTintColor
            $0.backgroundColor = self.backgroundColor
        }
        
        indicatorView >>> self >>> {
            $0.snp.makeConstraints {
                $0.leading.equalToSuperview().offset(16)
                $0.centerY.equalToSuperview()
                $0.width.height.equalTo(30)
            }
            $0.style = .medium
            $0.color = .white
        }
        
        loadingLabel >>> self >>> {
            $0.snp.makeConstraints {
                $0.leading.equalTo(indicatorView.snp.trailing).offset(8)
                $0.top.bottom.equalToSuperview()
            }
            $0.text = self.loadingString
            $0.textColor = .white
        }
    }
}
#endif
