//
//  CustomGrandientView.swift
//  SurvivalChallenge
//
//  Created by Apple on 1/5/25.
//
import UIKit

enum CustomGradientPoint {
    case topLeft
    case centerLeft
    case bottomLeft
    case topCenter
    case center
    case bottomCenter
    case topRight
    case centerRight
    case bottomRight
    var point: CGPoint {
        switch self {
        case .topLeft:
            return CGPoint(x: 0, y: 0)
        case .centerLeft:
            return CGPoint(x: 0, y: 0.5)
        case .bottomLeft:
            return CGPoint(x: 0, y: 1.0)
        case .topCenter:
            return CGPoint(x: 0.5, y: 0)
        case .center:
            return CGPoint(x: 0.5, y: 0.5)
        case .bottomCenter:
            return CGPoint(x: 0.5, y: 1.0)
        case .topRight:
            return CGPoint(x: 1.0, y: 0.0)
        case .centerRight:
            return CGPoint(x: 1.0, y: 0.5)
        case .bottomRight:
            return CGPoint(x: 1.0, y: 1.0)
        }
    }
}

class CustomGradientView: UIView {
    
    //MARK: Variables
    var colors: [UIColor] = [.black, .white] {
        didSet {
            self.gradientLayer.colors = colors.map({$0.cgColor})
            layoutIfNeeded()
        }
    }
    
    var startPoint: CustomGradientPoint = .centerLeft {
        didSet {
            self.gradientLayer.startPoint = startPoint.point
            layoutIfNeeded()
        }
    }
    
    var endPoint: CustomGradientPoint = .centerRight {
        didSet {
            self.gradientLayer.endPoint = endPoint.point
            layoutIfNeeded()
        }
    }
    
    var locations: [NSNumber] = [0.0, 1.0] {
        didSet {
            self.gradientLayer.locations = locations
            layoutIfNeeded()
        }
    }
    
    
    var type: CAGradientLayerType = .axial {
        didSet {
            self.gradientLayer.type = type
            layoutIfNeeded()
        }
    }
    
    private let gradientLayer = CAGradientLayer()
    
    //MARK: init
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}

//MARK: - functions
extension CustomGradientView {
    private func setupView() {
        gradientLayer.colors = colors.map({$0.cgColor})
        gradientLayer.startPoint = startPoint.point
        gradientLayer.endPoint = endPoint.point
        gradientLayer.locations = self.locations
        gradientLayer.frame = bounds
        
        layer.addSublayer(gradientLayer)
    }
}
