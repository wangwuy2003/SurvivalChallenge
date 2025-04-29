//
//  PHAssetManager.swift
//  MiTuKit
//
//  Created by Hồ Minh Tường on 21/11/21.
//  Copyright © 2021 - Present MiTu Ultra

#if os(iOS)
import Photos
import UIKit

public class PHAssetManager {
    public static let shared = PHAssetManager()
    private var storedPHImages: [PHImage] = []
    
    public var configs = PHAssetConfiguration.default()
    
    public var phFetchOptions: PHFetchOptions {
        get {
            configs.phFetchOptions
        }
        set {
            configs.phFetchOptions = newValue
        }
    }
    
    public var imageRequestOptions: PHImageRequestOptions {
        get {
            configs.imageRequestOptions
        }
        set {
            configs.imageRequestOptions = newValue
        }
    }
    
    public var targetSize: CGSize {
        get {
            configs.targetSize
        }
        set {
            configs.targetSize = newValue
        }
    }
    
    public var livePhotoRequestOptions: PHLivePhotoRequestOptions {
        get {
            return configs.livePhotoRequestOptions
        }
        set {
            configs.livePhotoRequestOptions = newValue
        }
    }
    
    public var videoRequestOptions: PHVideoRequestOptions {
        get {
            return configs.videoRequestOptions
        }
        set {
            configs.videoRequestOptions = newValue
        }
    }
}


public extension PHAssetManager {
    func getPHAssets(by identifiers: [String]) -> [PHAsset] {
        var assets: [PHAsset] = []
        let results = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: phFetchOptions)
        results.enumerateObjects { phAsset, _, _ in
            assets.append(phAsset)
        }
        return assets
    }
    
    func getPHAssets(with mediaType: PHAssetMediaType) -> [PHAsset] {
        var allAssets: [PHAsset] = []
        PHAsset.fetchAssets(with: mediaType, options: phFetchOptions).enumerateObjects { asset, _, _ in
            allAssets.append(asset)
        }
        return allAssets
    }
    
    func getImages(assets: [PHAsset], contentMode: PHImageContentMode = .aspectFit, targetSize: CGSize? = nil, completion: @escaping([PHImage]) -> Void) {
        let targetSize = targetSize ?? PHAssetManager.shared.targetSize
        var phImages: [PHImage] = []
        let group = DispatchGroup()
        for asset in assets {
            group.enter()
            if let phImage = self.getLocalImage(id: asset.localIdentifier, size: targetSize) {
                phImages.append(phImage)
                group.leave()
            } else {
                PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: contentMode, options: self.imageRequestOptions, resultHandler: { image, _ in
                    guard let image = image else {
                        print("cannot get image")
                        group.leave()
                        return
                    }
                    phImages.append(PHImage(asset: asset, image: image))
                    self.storedPHImages.append(PHImage(asset: asset, image: image))
                    group.leave()
                })
            }
        }
        group.notify(queue: .main, execute: {
            completion(phImages)
        })
    }
    
    func getImage(asset: PHAsset, contentMode: PHImageContentMode = .default, targetSize: CGSize? = nil, completion: @escaping(UIImage?) -> Void) {
        let targetSize = targetSize ?? PHAssetManager.shared.targetSize
        self.getImages(assets: [asset], targetSize: targetSize, completion: { image in
            completion(image.first?.image)
        })
    }
    
    func getLivePhoto(asset: PHAsset, completion: @escaping(PHLivePhoto?) -> Void) {
        PHImageManager.default().requestLivePhoto(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: self.livePhotoRequestOptions, resultHandler: { live, _ in
            completion(live)
        })
    }
    
    func getImageMaxSize(asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        self.getImage(asset: asset, targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight), completion: { img in
            completion(img)
        })
    }
    
    func getVideo(asset: PHAsset, completion: @escaping (AVURLAsset?) -> Void) {
        PHCachingImageManager.default().requestAVAsset(forVideo: asset, options: self.videoRequestOptions) { avulAsset, _, _ in
            completion(avulAsset as? AVURLAsset)
        }
    }
    
    func requestImageData(for asset: PHAsset, completion: @escaping(Data?) -> Void) {
        PHImageManager.default().requestImageDataAndOrientation(for: asset, options: self.imageRequestOptions, resultHandler: { data,_,_,_  in
            completion(data)
        })
    }
    
    func requestVideoData(for asset: PHAsset, completion: @escaping(Data?, Error?) -> Void) {
        PHImageManager.default().requestAVAsset(forVideo: asset, options: self.videoRequestOptions, resultHandler: { avasset, _, _ in
            if let avuAsset = avasset as? AVURLAsset {
                do {
                    completion(try Data(contentsOf: avuAsset.url), nil)
                } catch {
                    print(error.localizedDescription)
                    completion(nil, error)
                    return
                }
            } else {
                print("cannot convert asset to avurlAsset")
                completion(nil, MTError(title: "Something went wrong", description: "cannot convert asset to avurlAsset", code: -1))
                return
            }
        })
    }
    
    func requestVideoData(for asset: PHAsset) async -> Data? {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                PHImageManager.default().requestAVAsset(forVideo: asset, options: self.videoRequestOptions, resultHandler: { avasset, _, _ in
                    if let avuAsset = avasset as? AVURLAsset {
                        do {
                            continuation.resume(returning: try Data(contentsOf: avuAsset.url))
                        }
                        catch {
                            continuation.resume(throwing: error)
                        }
                    } else {
                        continuation.resume(throwing: MTError(title: "Something went wrong", description: "cannot convert asset to avurlAsset", code: -1))
                    }
                })
            }
        }
        catch {
            return nil
        }
    }
    
    func requestImageURL(from asset: PHAsset, completion: @escaping(URL?) -> Void) {
        asset.requestContentEditingInput(with: PHContentEditingInputRequestOptions()) { (editingInput, _) in
            completion(editingInput?.fullSizeImageURL)
        }
    }
    
    func requestImageURL(from asset: PHAsset) async -> URL? {
        return await withCheckedContinuation { continuation in
            asset.requestContentEditingInput(with: PHContentEditingInputRequestOptions()) { (editingInput, _) in
                continuation.resume(returning: editingInput?.fullSizeImageURL)
            }
        }
    }
    
    func requestVideoURL(from asset: PHAsset, completion: @escaping(URL?, Error?) -> Void) {
        PHImageManager.default().requestAVAsset(forVideo: asset, options: self.videoRequestOptions, resultHandler: { avasset, _, _ in
            if let avuAsset = avasset as? AVURLAsset {
                completion(avuAsset.url, nil)
            } else {
                print("cannot convert asset to avurlAsset")
                completion(nil, MTError(title: "Something went wrong", description: "cannot convert asset to avurlAsset", code: -1))
            }
        })
    }
    
    func requestVideoURL(from asset: PHAsset) async -> URL? {
        return await withCheckedContinuation { continuation in
            PHImageManager.default().requestAVAsset(forVideo: asset, options: self.videoRequestOptions, resultHandler: { avasset, _, _ in
                if let avuAsset = avasset as? AVURLAsset {
                    continuation.resume(returning: avuAsset.url)
                } else {
                    continuation.resume(returning: nil)
                }
            })
        }
    }
    
    func requestAVAsset(for asset: PHAsset, completion: @escaping(AVAsset?, AVAudioMix?, [AnyHashable : Any]?) -> Void) {
        PHImageManager.default().requestAVAsset(forVideo: asset, options: self.videoRequestOptions, resultHandler: completion)
    }
    
    func removeAsset(asset: PHAsset, completion: @escaping(Bool) -> Void) {
        self.removeAssets(assets: [asset], completion: completion)
    }
    
    func removeAssets(assets: [PHAsset], completion: @escaping(Bool) -> Void) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assets as NSFastEnumeration)
        } completionHandler: { (success, error) in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
}

public extension PHAssetManager {
    private func getLocalImage(id: String, size: CGSize) -> PHImage? {
        if let phImage = self.storedPHImages.first(where: {$0.asset.localIdentifier == id}) {
            if phImage.image.size.width >= size.width || phImage.image.size.height >= size.height {
                return phImage
            }
        }
        return nil
    }
}
#endif
