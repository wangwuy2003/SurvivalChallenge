//
//  MTTextLink.swift
//  MiTuKit
//
//  Created by Hồ Minh Tường on 21/11/21.
//  Copyright © 2021 - Present MiTu Ultra

#if os(iOS)
import Foundation
import UIKit

public class TextLink: UILabel {
    public override init(frame: CGRect) {
        super.init(frame: .zero)
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    private func setup() {
        self.isUserInteractionEnabled = true
        self.textColor = .link
    }
}

public extension TextLink {
    func getSize(_ completion: @escaping(CGSize) -> Void) {
        guard let font = self.font else { return }
        guard let text = self.text else { return }
        
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = (text).size(withAttributes: fontAttributes)
        completion(size)
    }
}

#endif
