//
//  PHAssetConfig.swift
//  MiTuKit
//
//  Created by Hồ Minh Tường on 21/11/21.
//  Copyright © 2021 - Present MiTu Ultra

#if os(iOS)
import Photos

public class PHAssetConfiguration: NSObject {
    private static var single = PHAssetConfiguration()
    
    @objc public class func `default`() -> PHAssetConfiguration {
        return PHAssetConfiguration.single
    }
    
    ///Default is 300x300
    public var targetSize = PHAssetConstants.shared.targetSize
    
    public var phFetchOptions: PHFetchOptions = PHAssetConstants.shared.phFetchOptions
    
    public var imageRequestOptions: PHImageRequestOptions = PHAssetConstants.shared.imageRequestOptions
    
    public var livePhotoRequestOptions: PHLivePhotoRequestOptions = PHAssetConstants.shared.livePhotoRequestOptions
    
    public var videoRequestOptions: PHVideoRequestOptions = PHAssetConstants.shared.videoRequestOptions
    
    
    ///Constants
    private class PHAssetConstants {
        static let shared = PHAssetConstants()
        
        
        let targetSize = CGSize(width: 300, height: 300)
        
        var phFetchOptions: PHFetchOptions {
            let options = PHFetchOptions()
            return options
        }
        
        var imageRequestOptions: PHImageRequestOptions {
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.resizeMode = .exact
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = true
            return options
        }
        
        var livePhotoRequestOptions: PHLivePhotoRequestOptions {
            let options = PHLivePhotoRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            return options
        }
        
        var videoRequestOptions:  PHVideoRequestOptions {
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            return options
        }
        
    }
}
#endif
