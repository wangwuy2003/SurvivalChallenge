//
//  AVCaptureVideoPreviewLayer+Exts.swift
//  SurvivalChallenge
//
//  Created by Apple on 28/4/25.
//
import Foundation
import UIKit
import AVFoundation

extension AVCaptureVideoPreviewLayer {
    func layerRectConverted(fromCaptureDeviceRect rect: CGRect, imageSize: CGSize) -> CGRect {
        let normalizedRect = CGRect(
            x: rect.origin.x / imageSize.width,
            y: rect.origin.y / imageSize.height,
            width: rect.width / imageSize.width,
            height: rect.height / imageSize.height
        )
        return self.layerRectConverted(fromMetadataOutputRect: normalizedRect)
    }
}
