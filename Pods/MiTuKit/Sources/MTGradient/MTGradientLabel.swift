//
//  MTGradientLabel.swift
//  MiTuKit
//
//  Created by Hồ Minh Tường on 21/11/21.
//  Copyright © 2021 - Present MiTu Ultra

#if os(iOS)
import UIKit

public class MTGradientLabel: UIView {
    
    //MARK: Variables
    public let label = UILabel()
    
    public var text: String? {
        didSet {
            self.label.text = text
        }
    }

    public var font: UIFont! {
        didSet {
            self.label.font = font
        }
    }

    public var textColor: UIColor! {
        didSet {
            self.label.textColor = textColor
        }
    }

    public var textAlignment: NSTextAlignment = .left {
        didSet {
            self.label.textAlignment = textAlignment
        }
    }

    public var lineBreakMode: NSLineBreakMode = .byWordWrapping {
        didSet {
            self.label.lineBreakMode = lineBreakMode
        }
    }

    public var numberOfLines: Int = 1 {
        didSet {
            self.label.numberOfLines = numberOfLines
        }
    }

    public var adjustsFontSizeToFitWidth: Bool = false {
        didSet {
            self.label.adjustsFontSizeToFitWidth = adjustsFontSizeToFitWidth
        }
    }
    
    public var colors: [UIColor] = [.black, .white] {
        didSet {
            self.gradientLayer.colors = colors.map({$0.cgColor})
            layoutIfNeeded()
        }
    }
    
    public var startPoint: MTGradientPoint = .centerLeft {
        didSet {
            self.gradientLayer.startPoint = startPoint.point
            layoutIfNeeded()
        }
    }
    
    public var endPoint: MTGradientPoint = .centerRight {
        didSet {
            self.gradientLayer.endPoint = endPoint.point
            layoutIfNeeded()
        }
    }
    
    public var locations: [NSNumber] = [0.0, 1.0] {
        didSet {
            self.gradientLayer.locations = locations
            layoutIfNeeded()
        }
    }
    
    
    public var type: CAGradientLayerType = .axial {
        didSet {
            self.gradientLayer.type = type
            layoutIfNeeded()
        }
    }
    
    private let gradientLayer = CAGradientLayer()

    //MARK: init
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}

//MARK: - functions
public extension MTGradientLabel {
    private func setupView() {
        gradientLayer.colors = colors.map({$0.cgColor})
        gradientLayer.startPoint = startPoint.point
        gradientLayer.endPoint = endPoint.point
        gradientLayer.locations = self.locations
        gradientLayer.frame = bounds
        
        layer.addSublayer(gradientLayer)
        
        label >>> self >>> {
            $0.snp.makeConstraints {
                $0.leading.equalToSuperview().offset(8)
                $0.trailing.equalToSuperview().offset(-8)
                $0.top.bottom.equalToSuperview()
            }
        }
    }
}

#endif
