//
//  MTCollectionView.swift
//  MiTuKit
//
//  Created by Hồ Minh Tường on 21/11/21.
//  Copyright © 2021 - Present MiTu Ultra


#if os(iOS)
import UIKit
import Foundation

public extension UICollectionView {
    enum ElementKind {
        case header
        case footer
    }
    
    func registerSupplementaryView<T: UICollectionViewCell>(viewClass: T.Type, elementKind: ElementKind = .header) {
        var kind = UICollectionView.elementKindSectionHeader
        if elementKind == .footer {
            kind = UICollectionView.elementKindSectionFooter
        }
        self.register(viewClass, forSupplementaryViewOfKind: kind, withReuseIdentifier: String(describing: viewClass))
    }
    
    func registerReusedCell<T: UICollectionViewCell>(_ cellClass: T.Type) {
        self.register(cellClass, forCellWithReuseIdentifier: String(describing: cellClass))
    }
    
    func dequeueReusable<T: UICollectionViewCell>(cellClass: T.Type, indexPath: IndexPath) -> T {
        return self.dequeueReusableCell(withReuseIdentifier: String(describing: cellClass), for: indexPath) as! T
    }
    
    func dequeueReusableSupplementary<T: UICollectionViewCell>(cellView: T.Type, elementKind: ElementKind = .header, indexPath: IndexPath) -> T {
        var kind = UICollectionView.elementKindSectionHeader
        if elementKind == .footer {
            kind = UICollectionView.elementKindSectionFooter
        }
        return self.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: String(describing: cellView), for: indexPath) as! T
    }
    
    
}

public extension UICollectionView {
    func reloadSections(index: Int, animation: Bool = false) {
        let sectionIndex = IndexSet(integer: index)
        if animation {
            self.reloadSections(sectionIndex)
        } else {
            UIView.performWithoutAnimation {
                self.reloadSections(sectionIndex)
            }
        }
        
    }
    
}

#endif
