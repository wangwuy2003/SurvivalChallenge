//
//  FileHelper.swift
//  EyeTrendFilter
//
//  Created by Hồ Hữu Nhân on 16/4/25.
//


import Foundation
internal import Alamofire
import AVKit

class FileHelper {
    static let shared = FileHelper()
    private init() {
        createFolderIfNeeded(folder: .videosCache)
        createFolderIfNeeded(folder: .audiosCache)
        createFolderIfNeeded(folder: .record)
    }
    
    enum FolderType: String {
        case videosCache
        case audiosCache
        case record
        case temp
    }
    
    private func baseURL(for folder: FolderType) -> URL {
        switch folder {
        case .record:
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        case .temp:
            return FileManager.default.temporaryDirectory
        default:
            return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        }
    }
    
    private func createFolderIfNeeded(folder: FolderType) {
        guard folder != .temp else { return }
        
        let folderURL = baseURL(for: folder).appendingPathComponent(folder.rawValue)
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            do {
                try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
                print("✅ Created folder: \(folder.rawValue)")
            } catch {
                print("⚠️ Failed to create folder \(folder.rawValue): \(error)")
            }
        }
    }
    
    func folderURL(for folder: FolderType) -> URL {
        switch folder {
        case .record:
            return baseURL(for: .record).appendingPathComponent(folder.rawValue)
        case .temp:
            return baseURL(for: .temp)
        default:
            return baseURL(for: folder).appendingPathComponent(folder.rawValue)
        }
    }
    
    func fileURL(fileName: String, in folder: FolderType) -> URL {
        let base = baseURL(for: folder)
        
        if folder == .temp {
            return base.appendingPathComponent(fileName)
        } else {
            return base.appendingPathComponent(folder.rawValue).appendingPathComponent(fileName)
        }
    }
    
    func fileExists(fileName: String, in folder: FolderType) -> Bool {
        let url = fileURL(fileName: fileName, in: folder)
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    func downloadFile(from remoteURL: URL, to localURL: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let destination: DownloadRequest.Destination = { _, _ in
                return (localURL, [.removePreviousFile, .createIntermediateDirectories])
            }
            
            AF.download(remoteURL, to: destination).response { response in
                if let error = response.error {
                    continuation.resume(throwing: error)
                } else {
                    print("✅ Downloaded file to: \(localURL)")
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    func saveVideoToRecordFolder(from sourceURL: URL, fileName: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            let destinationURL = fileURL(fileName: fileName, in: .record)
            
            do {
                let data = try Data(contentsOf: sourceURL)
                try data.write(to: destinationURL)
                continuation.resume(returning: true)
                print("✅ Saved video to: \(destinationURL)")
            } catch {
                continuation.resume(returning: false)
                print("⚠️ Failed to save video: \(error)")
            }
        }
    }
    
    func getAllVideosInRecordFolder() -> [URL] {
        let folderURL = folderURL(for: .record)
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
            let videoFiles = fileURLs.filter { $0.pathExtension.lowercased() == "mp4" }
            return videoFiles
        } catch {
            print("Failed to list videos: \(error)")
            return []
        }
    }
    
    func getThumbnail(for videoURL: URL) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            let cacheFileName = videoURL.lastPathComponent.replacingOccurrences(of: ".mp4", with: ".png")
            let cacheURL = fileURL(fileName: cacheFileName, in: .videosCache)
            
            if FileManager.default.fileExists(atPath: cacheURL.path),
               let data = try? Data(contentsOf: cacheURL),
               let image = UIImage(data: data) {
                continuation.resume(returning: image)
                return
            }
            
            DispatchQueue.global().async {
                let asset = AVAsset(url: videoURL)
                let imageGenerator = AVAssetImageGenerator(asset: asset)
                imageGenerator.appliesPreferredTrackTransform = true
                let time = CMTime(seconds: 0, preferredTimescale: 60)
                
                do {
                    let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                    let thumbnail = UIImage(cgImage: cgImage)
                    
                    // Cache thumbnail
                    if let data = thumbnail.pngData() {
                        try? data.write(to: cacheURL)
                        print("✅ Cached thumbnail: \(cacheFileName)")
                    }
                    
                    DispatchQueue.main.async {
                        continuation.resume(returning: thumbnail)
                    }
                } catch {
                    print("⚠️ Failed to generate thumbnail: \(error)")
                    DispatchQueue.main.async {
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
    }
    
    func removeFile(fileName: String, from folder: FolderType) async {
        await withCheckedContinuation { continuation in
            let fileURL = fileURL(fileName: fileName, in: folder)
            
            do {
                try FileManager.default.removeItem(at: fileURL)
                print("✅ Removed file: \(fileURL)")
            } catch {
                print("⚠️ Failed to remove file: \(error)")
            }
            continuation.resume()
        }
    }
}

