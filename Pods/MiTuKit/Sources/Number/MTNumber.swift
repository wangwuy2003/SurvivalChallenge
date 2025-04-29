//
//  MTNumber.swift
//  MiTuKit
//
//  Created by Hồ Minh Tường on 21/11/21.
//  Copyright © 2021 - Present MiTu Ultra


#if os(iOS)
import Foundation
import UIKit

public extension Numeric {
    var toDouble: Double {
        if let int = self as? Int {
            return Double(int)
        } else if let float = self as? Float {
            return Double(float)
        } else if let cgfloat = self as? CGFloat {
            return Double(cgfloat)
        } else if let double = self as? Double {
            return double
        } else if let int64 = self as? Int64 {
            return Double(int64)
        } else {
            let string = "\(self)"
            let formater = NumberFormatter()
            return formater.number(from: string)?.doubleValue ?? 0.0
        }
    }
    
    var toInt: Int {
        if let int = self as? Int {
            return int
        } else if let float = self as? Float {
            return Int(float)
        } else if let cgfloat = self as? CGFloat {
            return Int(cgfloat)
        } else if let double = self as? Double {
            return Int(double)
        } else if let int64 = self as? Int64 {
            return Int(int64)
        } else {
            let string = "\(self)"
            let formater = NumberFormatter()
            return formater.number(from: string)?.intValue ?? 0
        }
    }
    
    var toFloat: Float {
        if let int = self as? Int {
            return Float(int)
        } else if let float = self as? Float {
            return float
        } else if let cgfloat = self as? CGFloat {
            return Float(cgfloat)
        } else if let double = self as? Double {
            return Float(double)
        } else if let int64 = self as? Int64 {
            return Float(int64)
        } else {
            let string = "\(self)"
            let formater = NumberFormatter()
            return formater.number(from: string)?.floatValue ?? 0
        }
    }
    
    var cgFloat: CGFloat {
        if let int = self as? Int {
            return CGFloat(int)
        } else if let float = self as? Float {
            return CGFloat(float)
        } else if let cgfloat = self as? CGFloat {
            return cgfloat
        } else if let double = self as? Double {
            return CGFloat(double)
        } else if let int64 = self as? Int64 {
            return CGFloat(int64)
        } else {
            let string = "\(self)"
            let formater = NumberFormatter()
            let float = formater.number(from: string)?.floatValue ?? 0
            return CGFloat(float)
        }
    }
    
    var toString: String {
        if let int = self as? Int {
            return "\(int)"
        } else if let float = self as? Float {
            return "\(float)"
        } else if let cgfloat = self as? CGFloat {
            return "\(cgfloat)"
        } else if let double = self as? Double {
            return "\(double)"
        } else if let int64 = self as? Int64 {
            return "\(int64)"
        } else {
            let string = "\(self)"
            let formater = NumberFormatter()
            let float = formater.number(from: string)?.floatValue ?? 0
            return "\(float)"
        }
    }
    
    func timeString() -> String {
        var value: Int!
        if let int64 = self as? Int64 {
            value = Int(int64)
        } else if let int = self as? Int {
            value = int
        } else if let float = self as? Float {
            value = Int(float)
        } else if let cgfloat = self as? CGFloat {
            value = Int(cgfloat)
        } else if let double = self as? Double {
            value = Int(double)
        } else if let int64 = self as? Int64 {
            value = Int(int64)
        } else {
            return self.toString
        }
        
        let hour = value / 3600
        let minute = value / 60 % 60
        let second = value % 60

        // return formated string
        if hour > 0 {
            return String(format: "%02i:%02i:%02i", hour, minute, second)
        } else {
            return String(format: "%02i:%02i", minute, second)
        }
        
    }
    

    func toPrice(groupingSeparator: String = ",", decimalSeparator: String = ".") -> String {
        let number = self.toDouble
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = groupingSeparator
        formatter.decimalSeparator = decimalSeparator
        
        return formatter.string(from: NSNumber(value: number)) ?? ""
    }
}

public extension Int64 {
    func convertToGB() -> String {
        return ByteCountFormatter.string(fromByteCount: self, countStyle: ByteCountFormatter.CountStyle.decimal)
    }
    
    func toHMS(format: HMSFormat = .auto) -> String {
        let hours = self / 3600
        let minutes = (self % 3600) / 60
        let seconds = (self % 3600) % 60
        
        let hoursString = hours > 9 ? "\(hours)" : "0\(hours)"
        let minutesString = minutes > 9 ? "\(minutes)" : "0\(minutes)"
        let secondsString = seconds > 9 ? "\(seconds)" : "0\(seconds)"
        
        switch format {
        case .hhmmss:
            return "\(hoursString):\(minutesString):\(secondsString)"
        case .mmss:
            return "\(minutesString):\(secondsString)"
        case .auto:
            if hours > 0 {
                return "\(hoursString):\(minutesString):\(secondsString)"
            } else {
                return "\(minutesString):\(secondsString)"
            }
        }
    }
}

public enum HMSFormat {
    case hhmmss
    case mmss
    case auto
}

public extension Int {
    var toCounter: String {
        let number = Double(self)
        let sign = ((number < 0) ? "-" : "" )
        let num = fabs(number)

        if (num < 1000.0){
            return String(format:"\(sign)%g", num)
        }
        let exp: Int = Int(log10(num)/3.0)
        let units: [String] = ["K","M","B","T","P","E"]

        let roundedNum: Double = round(10 * num / pow(1000.0,Double(exp))) / 10

        return String(format:"\(sign)%g\(units[exp-1])", roundedNum)
    }
}

#endif
