//
//  LoadingLabel.swift
//  MiTuKit
//
//  Created by Hồ Minh Tường on 21/11/21.
//  Copyright © 2021 - Present MiTu Ultra

#if os(iOS)
import UIKit

public class LoadingLabel: UILabel {
    public var isLoading: Bool {
        return timer != nil
    }
    
    private var timer: Timer?
    
    public func startAnimating(timeInterval: TimeInterval = 0.5) {
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true, block: { timer in
            guard let text = self.text else {
                timer.invalidate()
                return
            }
            if text.contains("...") {
                self.text = self.text?.replacingOccurrences(of: "...", with: "")
            } else if text.contains("..") {
                self.text = self.text?.replacingOccurrences(of: "..", with: "...")
            } else if text.contains(".") {
                self.text = self.text?.replacingOccurrences(of: ".", with: "..")
            } else {
                self.text! += "."
            }
        })
    }
    
    public func stopAnimating() {
        timer?.invalidate()
        timer = nil
    }
}

#endif


