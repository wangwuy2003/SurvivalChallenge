//
//  UITableView+Exts.swift
//  AINoteTaker
//
//  Created by Apple on 21/3/25.
//

import UIKit

extension UITableView {
    func register<T: UITableViewCell>(_ cellClass: T.Type) {
        let reuseIdentifier = String(describing: cellClass)
        register(cellClass, forCellReuseIdentifier: reuseIdentifier)
    }
    
    func dequeueReuseableCell<T: UITableViewCell>(for indexPath: IndexPath) -> T {
        let reuseIdentifier = String(describing: T.self)
        guard let cell = dequeueReusableCell(withIdentifier: reuseIdentifier,
                                             for: indexPath) as? T else {
            fatalError("Cannot dequeue cell with identifier: \(reuseIdentifier)")
        }
        return cell
    }
}

extension UICollectionView {
    func register<T: UICollectionViewCell>(_ cellClass: T.Type) {
        let reuseIdentifier = String(describing: cellClass)
        register(cellClass, forCellWithReuseIdentifier: reuseIdentifier)
    }
    
    func dequeueReuseableCell<T: UICollectionViewCell>(for indexPath: IndexPath) -> T {
        let reuseIdentifier = String(describing: T.self)
        guard let cell = dequeueReusableCell(withReuseIdentifier: reuseIdentifier,
                                             for: indexPath) as? T else {
            fatalError("Cannot dequeue cell with identifier: \(reuseIdentifier)")
        }
        return cell
    }
}
