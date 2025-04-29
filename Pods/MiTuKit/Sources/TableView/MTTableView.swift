//
//  MTTableView.swift
//  MiTuKit
//
//  Created by Hồ Minh Tường on 21/11/21.
//  Copyright © 2021 - Present MiTu Ultra

#if os(iOS)
import Foundation
import UIKit

public extension UITableView {
    func registerReusedCell<T: UITableViewCell>(_ cellClass: T.Type) {
        self.register(cellClass, forCellReuseIdentifier: String(describing: cellClass))
    }
    
    func dequeueReusable<T: UITableViewCell>(cellClass: T.Type) -> T {
        return self.dequeueReusableCell(withIdentifier: String(describing: cellClass)) as! T
    }
    
    func dequeueReusable<T: UITableViewCell>(cellClass: T.Type, indexPath: IndexPath) -> T {
        return self.dequeueReusableCell(withIdentifier: String(describing: cellClass), for: indexPath) as! T
    }
    
}


public extension UITableView {
    func updateLayout(_ block: (() -> Void)? = nil) {
        self.beginUpdates()
        self.setNeedsLayout()
        if let completion = block {
            completion()
            self.endUpdates()
        } else {
            self.endUpdates()
        }
        
    }
}

#endif
