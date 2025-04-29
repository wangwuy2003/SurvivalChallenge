//
//  PHImage.swift
//  MiTuKit
//
//  Created by Hồ Minh Tường on 21/11/21.
//  Copyright © 2021 - Present MiTu Ultra

#if os(iOS)
import Photos
import UIKit

public struct PHImage {
    public let asset: PHAsset
    public let image: UIImage
}

#endif
