//
//  CenterZoomFlowLayout.swift
//  EyeTrendFilter
//
//  Created by Hồ Hữu Nhân on 16/4/25.
//

import UIKit

class CenterZoomFlowLayout: UICollectionViewFlowLayout {
    deinit {
        print("⚙️ deinit \(Self.self)")
    }
    
    override func prepare() {
        super.prepare()
        
        scrollDirection = .horizontal
        minimumInteritemSpacing = 16
        minimumLineSpacing = 27
        itemSize = CGSize(width: 52, height: 52)
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        var offsetAdjustment = CGFloat.greatestFiniteMagnitude
        let horizontalOffset = proposedContentOffset.x + collectionView!.contentInset.left
        let targetRect = CGRect(x: proposedContentOffset.x, y: 0, width: collectionView!.bounds.size.width, height: collectionView!.bounds.size.height)
        let layoutAttributesArray = super.layoutAttributesForElements(in: targetRect)
        layoutAttributesArray?.forEach({ (layoutAttributes) in
            let itemOffset = layoutAttributes.frame.origin.x
            if fabsf(Float(itemOffset - horizontalOffset)) < fabsf(Float(offsetAdjustment)) {
                offsetAdjustment = itemOffset - horizontalOffset
            }
        })
        return CGPoint(x: proposedContentOffset.x + offsetAdjustment, y: proposedContentOffset.y)
    }
}

class CenterModeFlowLayout: CenterZoomFlowLayout {
    deinit {
        print("⚙️ deinit \(Self.self)")
    }
    
    override func prepare() {
        super.prepare()
        
        scrollDirection = .horizontal
        minimumLineSpacing = 5
        itemSize = CGSize(width: 64, height: 28)
    }
}
