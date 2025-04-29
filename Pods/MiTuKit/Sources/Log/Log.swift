//
//  Log.swift
//  MiTuKit
//
//  Created by Hồ Minh Tường on 21/11/21.
//  Copyright © 2021 - Present MiTu Ultra

#if os(iOS)
import UIKit

// MARK: Debug Log
public func printDebug(_ items: Any..., file: String = #file, line: Int = #line) {
    #if DEBUG
        let p = file.components(separatedBy: "/").last ?? ""
        print("DEBUG \(p), Line: \(line): \(items)")
    #endif
}

public func printError(err: Error, file: String = #file, function: String = #function, line: Int = #line) {
    #if DEBUG
    let e = err as NSError
    var message = "\(e.domain) \(e.code)\n  \(e.localizedDescription)\n"
    if e.userInfo.count > 0 {
        message += "  UserInfo:\n"
        e.userInfo.forEach {
            message += "  -> \($0.key): \($0.value)\n"
        }
    }

    let displayName = file.components(separatedBy: "/").last ?? ""
    print("\(displayName) > [\(function) \(line) \(NSDate())]: \(message)")
    #endif
}

public func MTLog(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    let prefix = MTLogConfiguration.shared.prefix
    printDebug("\(prefix): \(items)")
}

public class MTLogConfiguration {
    public static let shared = MTLogConfiguration()
    
    public var prefix: String = "🐵"
}
#endif
