//
//  MTAsset.swift
//  MiTuKit
//
//  Created by Hồ Minh Tường on 21/11/21.
//  Copyright © 2021 - Present MiTu Ultra

#if os(iOS)
import Photos

public extension PHAsset {
    var fileSize: Int64 {
        get {
            if let ii = PHAssetResource.assetResources(for: self).first {
                if let sizei = ii.value(forKey: "fileSize") as? CLong {
                    let ii2 = Int64(bitPattern: UInt64(sizei))
                    return ii2
                } else {
                    return 0
                }
            } else {
               return 0
           }
        }
    }
}

#endif
