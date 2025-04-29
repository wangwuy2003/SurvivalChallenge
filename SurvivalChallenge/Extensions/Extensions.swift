//
//  Extensions.swift
//  SurvivalChallenge
//
//  Created by Apple on 24/4/25.
//

import Foundation
import UIKit

extension CGPoint {
    static func distance(from p1: CGPoint, to p2: CGPoint) -> CGFloat {
        return sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2))
    }
}
