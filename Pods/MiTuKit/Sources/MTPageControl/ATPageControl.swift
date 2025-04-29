//
//  MTPageControl.swift
//  MiTuKit
//
//  Created by Hồ Minh Tường on 21/11/21.
//  Copyright © 2021 - Present MiTu Ultra

#if os(iOS)
import UIKit

public class MTPageControl: UIView {
    public var numberOfPages: Int = 0 {
        didSet {
            
            dotViewArrayM.forEach { $0.removeFromSuperview() }
            dotViewArrayM.removeAll()
            
            for _ in 0..<numberOfPages {
                let dotView = UIView()
                dotView.layer.cornerRadius = cornerRadius
                addSubview(dotView)
                dotViewArrayM.append(dotView)
            }
            
            isInitialize = true
            setNeedsLayout()
        }
    }
    public var currentPage: Int {
        set {
            if (newValue < 0 ||
                newValue >= dotViewArrayM.count ||
                dotViewArrayM.count == 0 ||
                newValue == currentPage ||
                inAnimating)
            {
                return;
            }
            if (newValue > currentPage) {
                let currentView = dotViewArrayM[currentPage];
                bringSubviewToFront(currentView)
                inAnimating = true;
                UIView.animate(withDuration: self.animationDuration, animations: {
                    let x = currentView.frame.origin.x
                    let y = currentView.frame.origin.y
                    let w = self.currentDotWidth + (self.dotSpace + self.otherDotWidth) * CGFloat(newValue - self.currentPage)
                    let h = currentView.frame.size.height
                    currentView.frame = CGRect(x: x, y: y, width: w, height: h)
                }) { (finished) in
                    let endView = self.dotViewArrayM[newValue]
                    endView.backgroundColor = currentView.backgroundColor
                    endView.frame = currentView.frame
                    self.bringSubviewToFront(endView)
                    
                    currentView.backgroundColor = self.otherDotColor
                    
                    let start_X = currentView.frame.origin.x;
                    for i in 0..<(newValue - self.currentPage) {
                        
                        let dotView = self.dotViewArrayM[self.currentPage + i];
                        
                        let x = start_X + (self.otherDotWidth + self.dotSpace) * CGFloat(i)
                        let y = dotView.frame.origin.y
                        let w = self.otherDotWidth
                        let h = self.dotHeight
                        dotView.frame = CGRect(x: x, y: y, width: w, height: h)
                    }
                    UIView.animate(withDuration: self.animationDuration, animations: {
                        let w = self.currentDotWidth;
                        let x = endView.frame.maxX - self.currentDotWidth;
                        let y = endView.frame.origin.y;
                        let h = endView.frame.size.height;
                        endView.frame = CGRect(x: x, y: y, width: w, height: h)
                    }) { (finished) in
                        self.currentPageInner = newValue;
                        self.inAnimating = false;
                    }
                }
            }
            else
            {
                let currentView = self.dotViewArrayM[self.currentPage];
                bringSubviewToFront(currentView)
                inAnimating = true;
                
                UIView.animate(withDuration: self.animationDuration, animations: {
                    let x = currentView.frame.origin.x - (self.dotSpace + self.otherDotWidth) * CGFloat(self.currentPage - newValue);
                    let y = currentView.frame.origin.y;
                    let w = self.currentDotWidth + (self.dotSpace + self.otherDotWidth) * CGFloat(self.currentPage - newValue);
                    let h = currentView.frame.size.height;
                    currentView.frame = CGRect(x: x, y: y, width: w, height: h)
                }) { (_) in
                    let endView = self.dotViewArrayM[newValue]
                    endView.backgroundColor = currentView.backgroundColor
                    endView.frame = currentView.frame
                    self.bringSubviewToFront(endView)
                    
                    currentView.backgroundColor = self.otherDotColor
                    
                    let start_X = currentView.frame.maxX
                    for i in 0..<(self.currentPage - newValue) {
                        let dotView = self.dotViewArrayM[self.currentPage - i]
                        let tempFrame = dotView.frame
                        let x = start_X - self.otherDotWidth - (self.otherDotWidth + self.dotSpace) * CGFloat(i);
                        let y = tempFrame.origin.y
                        let w = self.otherDotWidth
                        let h = tempFrame.size.height
                        dotView.frame = CGRect(x: x, y: y, width: w, height: h)
                    }
                    
                    UIView.animate(withDuration: self.animationDuration, animations: {
                        let x = endView.frame.origin.x
                        let y = endView.frame.origin.y
                        let w = self.currentDotWidth
                        let h = endView.frame.size.height
                        endView.frame = CGRect(x: x, y: y, width: w, height: h)
                    }) { (_) in
                        self.currentPageInner = newValue
                        self.inAnimating = false
                    }
                }
            }
        }
        get {
            currentPageInner
        }
    }
    public var animationDuration: CGFloat = 0.3
    public var currentDotWidth: CGFloat = 0
    public var otherDotWidth: CGFloat = 0
    public var dotHeight: CGFloat = 0
    public var dotSpace: CGFloat = 0
    public var cornerRadius: CGFloat = 0
    public var currentDotColor: UIColor = .red
    public var otherDotColor: UIColor = .lightGray
    
    private var currentPageInner: Int = 0
    private var dotViewArrayM = [UIView]()
    private var isInitialize: Bool = false
    private var inAnimating: Bool = false
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        setupUI()
    }
    
    private func setupUI() {
        if dotViewArrayM.count == 0 || isInitialize == false {
            return
        }
        self.isInitialize = false
        
        let totalWidth = currentDotWidth + (CGFloat)(numberOfPages - 1) * (dotSpace + otherDotWidth)
        var currentX = (frame.size.width - totalWidth) / 2
        
        for i in 0..<dotViewArrayM.count {
            let dotView = dotViewArrayM[i]

            let width = (i == currentPage ? currentDotWidth : otherDotWidth)
            let height = dotHeight
            let x = currentX
            let y = (frame.size.height - height) / 2
            dotView.frame = CGRect(x: x, y: y, width: width, height: height)
            
            currentX = currentX + width + dotSpace
            
            dotView.backgroundColor = otherDotColor;
            if (i == currentPage) {
                dotView.backgroundColor = currentDotColor;
            }
        }
    }
}

#endif

