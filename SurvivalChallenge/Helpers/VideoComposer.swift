//
//  VideoComposer.swift
//  EyeTrendFilter
//
//  Created by Hồ Hữu Nhân on 18/4/25.
//


import UIKit
import AVFoundation

final class VideoComposer {
    // MARK: - Properties
    private var assetWriter: AVAssetWriter?
    private var assetWriterVideoInput: AVAssetWriterInput?
    private var assetWriterAudioInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private let videoProcessingQueue = DispatchQueue(label: "com.nhanhoo.videocomposer.processing", qos: .userInteractive)
    private let renderQueue = DispatchQueue(label: "com.nhanhoo.camera.videoQueue", qos: .userInteractive)
    
    private let videoSettings: [String: Any]
    private let audioSettings: [String: Any]
    var videoSegments: [URL] = []
    private var currentSegmentURL: URL?
    private var recordingStartTime: CMTime?
    private var isRecording = false
    private var isPaused = false
    
    // Capture đối tượng hiển thị
    private weak var viewToCapture: UIView?
    
    // Hiệu ứng
    private var effectType: FilterType = .none
    private var designType: DesignType?
    
    // Các thuộc tính cho context
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    
    // Thời điểm bắt đầu phân đoạn hiện tại
    private var segmentStartTime: Date?
    
    // Throttling và caching
    private var lastCaptureTime = Date()
    private var captureInterval: TimeInterval = 1.0/30.0 // 30fps target
    private var lastCapturedImage: UIImage?
    private var processingLock = NSLock()
    
    // Thêm các biến để theo dõi FPS
    private var frameCount: Int = 0
    private var lastFPSLogTime: TimeInterval = 0
    private let fpsLogInterval: TimeInterval = 1.0 // Log FPS mỗi giây
    
    // MARK: - Constants
    private let segmentsDirectory: URL
    
    deinit {
        print("⚙️ deinit \(Self.self)")
        assetWriter?.cancelWriting()
        assetWriter = nil
        assetWriterVideoInput = nil
        assetWriterAudioInput = nil
        pixelBufferAdaptor = nil
    }
    
    init(width: Int = 720, height: Int = 1280, fps: Int = 30) {
        // Tạo thư mục lưu các phân đoạn video (trong temp directory)
        self.segmentsDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("VideoSegments", isDirectory: true)
        
        // Tạo thư mục nếu chưa tồn tại
        do {
            try FileManager.default.createDirectory(at: segmentsDirectory, withIntermediateDirectories: true, attributes: nil)
            print("✅ Created temp segments directory: \(segmentsDirectory.path)")
        } catch {
            print("⚠️ Failed to create temp segments directory: \(error.localizedDescription)")
        }
        
        // Cấu hình video settings với độ phân giải thấp hơn
        videoSettings = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 5000000,
                AVVideoMaxKeyFrameIntervalKey: 30,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel, // Thay đổi thành High thay vì Baseline
                AVVideoExpectedSourceFrameRateKey: 30,
                AVVideoMaxKeyFrameIntervalDurationKey: 1 // Thêm để tăng cường chất lượng
            ]
        ]
        
        // Cấu hình audio settings
        audioSettings = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey: 2,
            AVSampleRateKey: 44100,
            AVEncoderBitRateKey: 96000 // Giảm bitrate audio
        ]
        
        // Điều chỉnh framerate cho capture
        captureInterval = 1.0 / Double(fps)
        
        print("⚙️ VideoComposer initialized with resolution: \(width)x\(height), fps: \(fps)")
    }
    
    // MARK: - Recording Methods
    
    /// Thiết lập view cần ghi
    func setViewToCapture(_ view: UIView) {
        self.viewToCapture = view
    }
    
    /// Thiết lập loại hiệu ứng và view tương ứng
    func setEffectType(_ type: FilterType, designType: DesignType?, view: UIView) {
        self.effectType = type
        self.designType = designType
        self.viewToCapture = view
        print("✅ Set effect type to: \(type)")
    }
    
    private func setupAssetWriter(url: URL) {
        do {
            assetWriter = try AVAssetWriter(url: url, fileType: .mov)
            
            // Tăng tốc độ ghi bằng cách giảm độ ưu tiên chất lượng
            assetWriter?.movieFragmentInterval = CMTime(seconds: 1, preferredTimescale: 1000)
            assetWriter?.shouldOptimizeForNetworkUse = false // Tắt tối ưu network để tăng tốc độ ghi
            
            // Tạo video input
            assetWriterVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            assetWriterVideoInput?.expectsMediaDataInRealTime = true
            // Tăng kích thước buffer để xử lý các spike trong CPU usage
            assetWriterVideoInput?.performsMultiPassEncodingIfSupported = false // Tắt multi-pass encoding
            
            // Thêm video input vào asset writer
            if let assetWriter = assetWriter, let videoInput = assetWriterVideoInput {
                if assetWriter.canAdd(videoInput) {
                    assetWriter.add(videoInput)
                } else {
                    print("⚠️ Could not add video input to asset writer")
                    return
                }
            }
            
            // Tạo pixel buffer adaptor với các thuộc tính đơn giản hơn
            let attributes: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
                kCVPixelBufferWidthKey as String: videoSettings[AVVideoWidthKey] as? Int ?? 720,
                kCVPixelBufferHeightKey as String: videoSettings[AVVideoHeightKey] as? Int ?? 1280
            ]
            
            pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: assetWriterVideoInput!,
                sourcePixelBufferAttributes: attributes
            )
            
            // Bắt đầu ghi
            assetWriter?.startWriting()
            
            // recordingStartTime sẽ được thiết lập khi frame đầu tiên đến
            recordingStartTime = nil
            
            // Khởi tạo các biến theo dõi
            segmentStartTime = Date()
            lastCaptureTime = Date()
            lastCapturedImage = nil
            
            isRecording = true
            isPaused = false
            
            print("✅ Recording started to: \(url.path)")
            
        } catch {
            print("⚠️ Failed to start recording: \(error.localizedDescription)")
            // Thử tạo mới URL nếu thất bại
            let newTimestamp = Date().timeIntervalSince1970 + 1
            if let newURL = segmentsDirectory.appendingPathComponent("segment_retry_\(newTimestamp).mov") as URL? {
                currentSegmentURL = newURL
                setupAssetWriter(url: newURL)
            }
        }
    }
    
    /// Tạm dừng ghi
    func pauseRecording() {
        guard isRecording && !isPaused else {
            print("⚙️ Not recording or already paused")
            return
        }
        
        isPaused = true
        print("⚙️ Recording paused")
        
        // Mỗi khi pause, finalizing segment hiện tại và lưu vào danh sách
        finalizeCurrentSegment()
    }
    
    private func finalizeCurrentSegment() {
        // Kiểm tra trạng thái recording
        guard isRecording, let currentURL = currentSegmentURL, let writer = assetWriter else {
            print("⚠️ No active segment to finalize")
            return
        }
        
        // Kiểm tra trạng thái của writer trước khi finalize
        if writer.status != .writing {
            print("⚠️ Cannot finalize segment: writer status is \(writer.status.rawValue)")
            return
        }
        
        // Đánh dấu inputs đã hoàn thành
        assetWriterVideoInput?.markAsFinished()
        assetWriterAudioInput?.markAsFinished()
        
        // Finalize writing với try-catch để tránh crash
        let finishGroup = DispatchGroup()
        finishGroup.enter()
        
        writer.finishWriting { [weak self] in
            defer { finishGroup.leave() }
            
            guard let self = self else { return }
            
            if writer.status == .completed {
                print("✅ Segment finalized successfully")
                
                // Thêm segment URL vào danh sách
                self.videoSegments.append(currentURL)
                print("✅ Added segment to list: \(currentURL.lastPathComponent)")
            } else {
                print("⚠️ Failed to finalize segment: \(writer.error?.localizedDescription ?? "Unknown error")")
                
                // Thử phương án dự phòng
                if FileManager.default.fileExists(atPath: currentURL.path),
                   let attributes = try? FileManager.default.attributesOfItem(atPath: currentURL.path),
                   let fileSize = attributes[.size] as? UInt64,
                   fileSize > 1000 {
                    
                    // Thêm vào danh sách dù có lỗi
                    self.videoSegments.append(currentURL)
                    print("⚙️ Added segment to list (with errors): \(currentURL.lastPathComponent)")
                }
            }
            
            // Reset các biến
            self.assetWriter = nil
            self.assetWriterVideoInput = nil
            self.assetWriterAudioInput = nil
            self.pixelBufferAdaptor = nil
            self.currentSegmentURL = nil
        }
        
        // Set timeout
        _ = finishGroup.wait(timeout: .now() + 3.0)
    }
    
    /// Tiếp tục ghi sau khi tạm dừng - luôn tạo segment mới
    func resumeRecording() {
        // Nếu đang recording nhưng đã pause
        if isRecording && isPaused {
            // Đảm bảo reset trạng thái trước khi tạo segment mới
            isPaused = false
            isRecording = false  // Reset để startRecording() hoạt động đúng
            
            // Tạo segment mới - gọi hàm startRecording để tạo URL mới
            startRecording()
            
            print("⚙️ Recording resumed with new segment")
        }
        // Nếu chưa bắt đầu recording
        else if !isRecording {
            startRecording()
        }
    }

    /// Bắt đầu ghi một segment mới
    func startRecording() {
        // Kiểm tra xem đã đang ghi chưa
        if isRecording && !isPaused {
            print("⚙️ Already recording")
            return
        }
        
        // Tạo URL cho segment mới
        let timestamp = Date().timeIntervalSince1970
        currentSegmentURL = segmentsDirectory.appendingPathComponent("segment_\(timestamp).mp4")
        
        guard let url = currentSegmentURL else {
            print("⚠️ Failed to create segment URL")
            return
        }
        
        print("⚙️ Creating new segment: \(url.lastPathComponent)")
        
        // Tiếp tục với quá trình thiết lập
        setupAssetWriter(url: url)
    }
    
    /// Dừng ghi phân đoạn hiện tại
    func stopRecording(completion: ((Bool) -> Void)? = nil) {
        print("⚙️ stopRecording called, current state: isRecording=\(isRecording), isPaused=\(isPaused)")
        
        if !isRecording {
            print("⚙️ Not recording, already stopped")
            isRecording = false  // Đảm bảo flag được reset
            isPaused = false     // Đảm bảo flag được reset
            completion?(true)    // Trả về true vì đã dừng
            return
        }
        
        // Reset trạng thái ngay lập tức để ngăn việc nhận frames mới
        isRecording = false
        isPaused = false
        
        // Kiểm tra trạng thái trước khi finalize
        if let writer = assetWriter, let currentURL = currentSegmentURL {
            if writer.status != .writing {
                print("⚠️ Cannot finalize recording: writer status is \(writer.status.rawValue)")
                completion?(false)
                return
            }
            
            // Đánh dấu inputs đã hoàn thành
            assetWriterVideoInput?.markAsFinished()
            assetWriterAudioInput?.markAsFinished()
            
            // Finalize với try-catch
            writer.finishWriting { [weak self] in
                guard let self = self else {
                    completion?(false)
                    return
                }
                
                if writer.status == .completed {
                    print("✅ Recording finalized successfully")
                    
                    // Thêm segment URL vào danh sách
                    self.videoSegments.append(currentURL)
                    print("✅ Added segment to list: \(currentURL.lastPathComponent)")
                    
                    completion?(true)
                } else {
                    print("⚠️ Failed to finalize recording: \(writer.error?.localizedDescription ?? "Unknown error")")
                    
                    // Thử phương án dự phòng
                    if FileManager.default.fileExists(atPath: currentURL.path),
                       let attributes = try? FileManager.default.attributesOfItem(atPath: currentURL.path),
                       let fileSize = attributes[.size] as? UInt64,
                       fileSize > 1000 {
                        
                        // Thêm vào danh sách dù có lỗi
                        self.videoSegments.append(currentURL)
                        print("⚙️ Added segment to list (with errors): \(currentURL.lastPathComponent)")
                        completion?(true)
                    } else {
                        completion?(false)
                    }
                }
                
                // Reset các biến
                self.assetWriter = nil
                self.assetWriterVideoInput = nil
                self.assetWriterAudioInput = nil
                self.pixelBufferAdaptor = nil
                self.currentSegmentURL = nil
            }
        } else {
            completion?(false)
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.logSegmentsInfo()
        }
    }

    // Thêm một phương thức để debug các segments
    func logSegmentsInfo() {
        print("📊 Current segments (\(videoSegments.count)):")
        for (index, url) in videoSegments.enumerated() {
            if FileManager.default.fileExists(atPath: url.path),
               let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
               let fileSize = attributes[.size] as? UInt64 {
                print("   \(index+1). \(url.lastPathComponent) - \(ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file))")
            } else {
                print("   \(index+1). \(url.lastPathComponent) - INVALID")
            }
        }
    }
    
    /// Finalize recording của segment hiện tại
    private func finalizeRecording(completion: @escaping (Bool) -> Void) {
        guard let writer = assetWriter else {
            print("⚠️ No asset writer to finalize")
            completion(false)
            return
        }
        
        print("⚙️ Finalizing recording")
        
        // Đánh dấu các inputs đã hoàn thành
        assetWriterVideoInput?.markAsFinished()
        assetWriterAudioInput?.markAsFinished()
        
        // Finalize writing với timeout
        let finishGroup = DispatchGroup()
        finishGroup.enter()
        
        writer.finishWriting { [weak self] in
            defer { finishGroup.leave() }
            
            guard let writer = self?.assetWriter else {
                completion(false)
                return
            }
            
            if writer.status == .completed {
                print("✅ Recording finalized successfully")
                completion(true)
            } else {
                print("⚠️ Failed to finalize recording: \(writer.error?.localizedDescription ?? "Unknown error")")
                
                // Thử phương án dự phòng: copy file nếu có thể
                if let url = self?.currentSegmentURL,
                   FileManager.default.fileExists(atPath: url.path),
                   let fileSize = try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? UInt64,
                   fileSize > 1000 { // Kiểm tra file có kích thước tối thiểu
                    print("⚙️ Using backup approach for finalization")
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
        
        // Set timeout
        DispatchQueue.global(qos: .background).async {
            let result = finishGroup.wait(timeout: .now() + 3.0)
            if result == .timedOut {
                print("⚠️ Finalize writing timed out")
                completion(false)
            }
        }
    }
    
    /// Hợp nhất tất cả các phân đoạn để tạo video cuối cùng
    func finalizeAndExportVideo(completion: @escaping (URL?) -> Void) {
        print("📊 Final segments before export (\(videoSegments.count)):")
        for (index, url) in videoSegments.enumerated() {
            print("   \(index+1). \(url.lastPathComponent)")
            inspectSegment(at: url, index: index+1)
        }
        
        // In thông tin segment
        print("📊 Current segments (\(videoSegments.count)):")
        for (index, url) in videoSegments.enumerated() {
            if FileManager.default.fileExists(atPath: url.path),
               let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
               let fileSize = attributes[.size] as? UInt64 {
                print("   \(index+1). \(url.lastPathComponent) - \(ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file))")
            } else {
                print("   \(index+1). \(url.lastPathComponent) - INVALID")
            }
        }
        
        print("⚙️ CALLING MERGE SEGMENTS METHOD")
        print("⚙️ Recording status: isRecording=\(isRecording), isPaused=\(isPaused)")
        
        // Phát hiện sự cố: Bỏ qua isRecording check và luôn merge nếu có segments
        if !videoSegments.isEmpty {
            print("⚙️ Segments available, using SIMPLE merge method")
            self.simpleMergeSegments(completion: completion)
        } else {
            print("⚠️ No segments to export")
            completion(nil)
        }
    }
    
    private func inspectSegment(at url: URL, index: Int) {
        print("🔍 INSPECTING SEGMENT \(index): \(url.lastPathComponent)")
        
        // Kiểm tra file tồn tại
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("   - File does not exist!")
            return
        }
        
        // Kiểm tra kích thước file
        if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
           let fileSize = attributes[.size] as? UInt64 {
            print("   - File size: \(ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file))")
        }
        
        // Load asset
        let asset = AVAsset(url: url)
        
        // Kiểm tra duration
        let duration = CMTimeGetSeconds(asset.duration)
        print("   - Duration: \(duration) seconds")
        
        // Kiểm tra tracks
        let videoTracks = asset.tracks(withMediaType: .video)
        print("   - Video tracks: \(videoTracks.count)")
        
        for (i, track) in videoTracks.enumerated() {
            print("     - Video track \(i+1): duration=\(CMTimeGetSeconds(track.timeRange.duration))s, size=\(track.naturalSize)")
        }
        
        let audioTracks = asset.tracks(withMediaType: .audio)
        print("   - Audio tracks: \(audioTracks.count)")
        
        // Kiểm tra readable
        asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            var error: NSError? = nil
            let status = asset.statusOfValue(forKey: "duration", error: &error)
            DispatchQueue.main.async {
                if status == .loaded {
                    print("   - Asset is readable")
                } else {
                    print("   - Asset may not be readable: \(error?.localizedDescription ?? "unknown error")")
                }
            }
        }
    }
    
    private func simpleMergeSegments(completion: @escaping (URL?) -> Void) {
        print("⚙️ STARTING MERGE")
        
        if videoSegments.count == 0 {
            print("⚠️ No segments to merge")
            completion(nil)
            return
        }
        
        if videoSegments.count == 1 {
            print("✅ Only one segment, no need to merge")
            completion(videoSegments[0])
            return
        }
        
        print("📊 Starting simple merge of \(videoSegments.count) segments")
        
        // Lọc bỏ segments không tồn tại
        let validSegments = videoSegments.filter { url in
            let exists = FileManager.default.fileExists(atPath: url.path)
            if !exists {
                print("⚠️ Segment file not found: \(url.path)")
            }
            return exists
        }
        
        if validSegments.isEmpty {
            print("⚠️ No valid segments to merge")
            completion(nil)
            return
        }
        
        if validSegments.count == 1 {
            print("✅ Only one valid segment remaining, returning it")
            completion(validSegments[0])
            return
        }
        
        // Tạo URL cho file đầu ra
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("simple_merged_\(Date().timeIntervalSince1970).mov")
        print("🔥 Output file will be: \(outputURL.lastPathComponent)")
        
        // Tạo composition
        let composition = AVMutableComposition()
        print("🔥 Created composition")
        
        // Tạo video track trong composition
        guard let compositionVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            print("⚠️ Failed to create composition video track")
            completion(validSegments[0])
            return
        }
        print("🔥 Created video track in composition")
        
        // Thời gian bắt đầu chèn
        var currentTime = CMTime.zero
        print("🔥 Starting at time: \(CMTimeGetSeconds(currentTime))")
        
        // Duyệt qua từng segment và thêm vào composition
        for (index, segmentURL) in validSegments.enumerated() {
            print("🔥 Processing segment \(index + 1): \(segmentURL.lastPathComponent)")
            
            let asset = AVAsset(url: segmentURL)
            
            // Log thời lượng của segment
            let segmentDuration = CMTimeGetSeconds(asset.duration)
            print("🔥 Segment \(index + 1) duration: \(segmentDuration) seconds")
            
            // Lấy video track từ segment
            guard let videoTrack = asset.tracks(withMediaType: .video).first else {
                print("⚠️ No video track in segment \(index + 1)")
                continue
            }
            
            // Thêm video track vào composition
            do {
                let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
                print("🔥 Adding segment \(index + 1) at position \(CMTimeGetSeconds(currentTime))")
                
                try compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: currentTime)
                print("✅ Added video track from segment \(index + 1)")
            } catch {
                print("⚠️ Error adding video track for segment \(index + 1): \(error.localizedDescription)")
                print("⚠️ Error details: \(error)")
                continue
            }
            
            // Cập nhật thời gian cho segment tiếp theo
            let oldTime = CMTimeGetSeconds(currentTime)
            currentTime = CMTimeAdd(currentTime, asset.duration)
            print("🔥 Updated insert time from \(oldTime) to \(CMTimeGetSeconds(currentTime)) seconds")
        }
        
        // Log tổng thời lượng
        print("🔥 Total composition duration: \(CMTimeGetSeconds(composition.duration)) seconds")
        
        // Nếu composition rỗng hoặc không có duration
        if CMTimeGetSeconds(composition.duration) <= 0 {
            print("⚠️ Composition has no duration after adding segments")
            completion(validSegments[0])
            return
        }
        
        // Tạo export session
        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetMediumQuality
        ) else {
            print("⚠️ Could not create export session")
            completion(validSegments[0])
            return
        }
        
        // Thiết lập export session
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.shouldOptimizeForNetworkUse = true
        
        print("🔥 Starting export with preset: \(exportSession.presetName)")
        
        // Export video
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                print("🔥 Export completed with status: \(exportSession.status.rawValue)")
                
                if exportSession.status == .completed {
                    let exportedAsset = AVAsset(url: outputURL)
                    let finalDuration = CMTimeGetSeconds(exportedAsset.duration)
                    
                    print("✅ Successfully exported merged video:")
                    print("   - Duration: \(finalDuration) seconds")
                    print("   - Path: \(outputURL.path)")
                    
                    // Kiểm tra kích thước file
                    if let attributes = try? FileManager.default.attributesOfItem(atPath: outputURL.path),
                       let fileSize = attributes[.size] as? UInt64 {
                        print("   - File size: \(ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file))")
                    }
                    
                    completion(outputURL)
                } else {
                    print("⚠️ Export failed with status: \(exportSession.status.rawValue)")
                    if let error = exportSession.error {
                        print("   - Error: \(error.localizedDescription)")
                        print("   - Error details: \(error)")
                    }
                    completion(validSegments[0])
                }
            }
        }
    }
    
    /// Loại bỏ segment cuối cùng
    func discardLastSegment() {
        guard !videoSegments.isEmpty else {
            print("⚙️ No segments to discard")
            return
        }
        
        let lastSegmentURL = videoSegments.removeLast()
        
        do {
            try FileManager.default.removeItem(at: lastSegmentURL)
            print("✅ Discarded last segment: \(lastSegmentURL.lastPathComponent)")
        } catch {
            print("⚠️ Failed to delete segment file: \(error.localizedDescription)")
        }
    }
    
    /// Xóa tất cả các segments
    func clearSegments() {
        for url in videoSegments {
            do {
                try FileManager.default.removeItem(at: url)
                print("⚙️ Removed segment: \(url.lastPathComponent)")
            } catch {
                print("⚠️ Failed to delete segment: \(error.localizedDescription)")
            }
        }
        
        videoSegments.removeAll()
        print("✅ All segments cleared")
    }
    
    /// Hủy bỏ tất cả recordings
    func cancelAllRecordings() {
        // Dừng recording hiện tại nếu đang ghi
        if isRecording {
            assetWriter?.cancelWriting()
            assetWriter = nil
            assetWriterVideoInput = nil
            assetWriterAudioInput = nil
            pixelBufferAdaptor = nil
            
            isRecording = false
            isPaused = false
        }
        
        // Xóa tất cả các segments
        for url in videoSegments {
            do {
                try FileManager.default.removeItem(at: url)
                print("⚙️ Removed segment: \(url.lastPathComponent)")
            } catch {
                print("⚠️ Failed to delete segment: \(error.localizedDescription)")
            }
        }
        
        // Xóa segment hiện tại nếu có
        if let currentURL = currentSegmentURL {
            do {
                try FileManager.default.removeItem(at: currentURL)
                print("⚙️ Removed current segment: \(currentURL.lastPathComponent)")
            } catch {
                print("⚠️ Failed to delete current segment: \(error.localizedDescription)")
            }
        }
        
        // Xóa danh sách segments
        videoSegments.removeAll()
        currentSegmentURL = nil
        
        print("✅ All recordings cancelled")
    }
    
    // MARK: - Sample Buffer Processing
    
    /// Xử lý sample buffer từ camera với cơ chế throttling để giảm áp lực xử lý
    func processSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        // Chỉ kiểm tra điều kiện cần thiết
        guard isRecording && !isPaused else {
            return
        }
        
        // Theo dõi FPS (giữ lại để debug)
        let now = CACurrentMediaTime() // Sử dụng CACurrentMediaTime thay vì Date() để hiệu quả hơn
        frameCount += 1
        let fpsElapsed = now - lastFPSLogTime
        if fpsElapsed >= fpsLogInterval {
            let currentFPS = Double(frameCount) / fpsElapsed
            print("📊 FPS: \(String(format: "%.1f", currentFPS)) frames/second")
            
            // Reset bộ đếm
            frameCount = 0
            lastFPSLogTime = now
        }
        
        // Kiểm tra trạng thái assetWriter
        guard let writer = assetWriter,
              writer.status == .writing || writer.status == .unknown,
              let input = assetWriterVideoInput,
              input.isReadyForMoreMediaData else {
            return
        }
        
        // Thiết lập recordingStartTime nếu là frame đầu tiên
        if recordingStartTime == nil {
            recordingStartTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            writer.startSession(atSourceTime: recordingStartTime!)
            print("✅ Recording session started at: \(recordingStartTime!.seconds)")
        }
        
        // Xử lý frame dựa trên loại hiệu ứng được chọn - không dùng thêm queue
        captureAndProcessFrame(sampleBuffer, input: input)
    }

    // Hàm mới tách ra từ processSampleBuffer
    private func captureAndProcessFrame(_ sampleBuffer: CMSampleBuffer, input: AVAssetWriterInput) {
        // Sử dụng một khóa nhẹ để tránh xung đột
        processingLock.lock()
        defer { processingLock.unlock() }
        
        // Dựa vào loại hiệu ứng để lấy frame
        if let image = captureFrameFromView(effectType) {
            // Lưu lại hình ảnh đã chụp để có thể tái sử dụng
            lastCapturedImage = image
            
            // Tạo pixel buffer từ image
            if let pixelBuffer = createOptimizedPixelBuffer(from: image),
               let adaptor = pixelBufferAdaptor {
                
                // Tính toán thời gian hiện tại cho frame
                let currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                
                // Ghi pixel buffer trực tiếp không qua queue
                if input.isReadyForMoreMediaData {
                    if !adaptor.append(pixelBuffer, withPresentationTime: currentTime) {
                        if let error = assetWriter?.error {
                            print("⚠️ Failed to append pixel buffer: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
    
    /// Chụp frame từ view hiệu ứng
    private func captureFrameFromView(_ effectType: FilterType) -> UIImage? {
        // Lấy view dựa trên hiệu ứng
//        let viewToCapture: UIView?
//        
//        switch effectType {
//        case .timeWarpScan, .eyeTrend:
//            viewToCapture = effectView
//        default:
//            return nil
//        }
        
        guard let view = viewToCapture else {
            return nil
        }
        
        // Giảm độ phân giải nhiều hơn để ưu tiên độ mượt
        let scale: CGFloat = 0.6 // Giảm kích thước từ 0.8 xuống 0.6
        
        var resultImage: UIImage?
        
        // Đảm bảo chụp ảnh trên main thread nếu đang ở thread khác
        if Thread.isMainThread {
            UIGraphicsBeginImageContextWithOptions(view.bounds.size, true, scale) // Sử dụng opaque=true để tăng tốc render
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: false)
            resultImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        } else {
            // Thử bỏ qua semaphore và sử dụng cached image nếu không thể chụp kịp thời
            let semaphore = DispatchSemaphore(value: 0)
            
            DispatchQueue.main.async {
                UIGraphicsBeginImageContextWithOptions(view.bounds.size, true, scale) // Sử dụng opaque=true
                view.drawHierarchy(in: view.bounds, afterScreenUpdates: false)
                resultImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                semaphore.signal()
            }
            
            // Giảm timeout để không chờ quá lâu
            let waitResult = semaphore.wait(timeout: .now() + 0.03)
            
            // Nếu timeout, sử dụng hình ảnh đã chụp trước đó
            if waitResult == .timedOut && self.lastCapturedImage != nil {
                return self.lastCapturedImage
            }
        }
        
        return resultImage
    }
    
    /// Tạo pixel buffer từ UIImage với các tối ưu
    private func createOptimizedPixelBuffer(from image: UIImage) -> CVPixelBuffer? {
        // Lấy kích thước từ video settings
        let width = videoSettings[AVVideoWidthKey] as? Int ?? 720
        let height = videoSettings[AVVideoHeightKey] as? Int ?? 1280
        
        var pixelBuffer: CVPixelBuffer?
        
        // Tạo pixel buffer với các thuộc tính tối thiểu
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA, // BGRA có thể hiệu quả hơn trên iOS
            [kCVPixelBufferIOSurfacePropertiesKey: [:]] as CFDictionary,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else {
            CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
            return nil
        }
        
        // Vẽ nền đen
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        
        // Vẽ hình ảnh với aspect fit
        if let cgImage = image.cgImage {
            let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
            let drawRect = AVMakeRect(aspectRatio: imageSize, insideRect: CGRect(x: 0, y: 0, width: width, height: height))
            
            context.draw(cgImage, in: drawRect)
        }
        
        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return buffer
    }
    
    // MARK: - Helper Methods
    
    /// Kiểm tra tất cả các segments có hợp lệ không
    func validateSegments() {
        // Lọc bỏ các segments không tồn tại hoặc kích thước = 0
        let validSegments = videoSegments.filter { url in
            if !FileManager.default.fileExists(atPath: url.path) {
                print("⚠️ Removing invalid segment: \(url.lastPathComponent) - file not found")
                return false
            }
            
            if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
               let fileSize = attributes[.size] as? UInt64, fileSize == 0 {
                print("⚠️ Removing invalid segment: \(url.lastPathComponent) - file size is 0")
                return false
            }
            
            return true
        }
        
        // Cập nhật danh sách
        if validSegments.count != videoSegments.count {
            print("⚙️ Removed \(videoSegments.count - validSegments.count) invalid segments")
            videoSegments = validSegments
        } else {
            print("✅ All \(videoSegments.count) segments are valid")
        }
    }
    
    /// Reset composer để sẵn sàng cho recording mới
    func resetComposer() {
        // Đảm bảo dừng mọi recording đang diễn ra
        if isRecording {
            stopRecording { _ in
                // Do nothing with result
            }
        }
        
        // Giữ lại các segments đã quay trước đó
        // Chỉ xóa các biến trạng thái
        isRecording = false
        isPaused = false
        
        // Reset các writer
        assetWriter = nil
        assetWriterVideoInput = nil
        assetWriterAudioInput = nil
        pixelBufferAdaptor = nil
        
        // Reset biến hẹn giờ
        recordingStartTime = nil
        segmentStartTime = nil
        lastCaptureTime = Date()
        lastCapturedImage = nil
        
        print("⚙️ VideoComposer reset and ready for new recording")
    }

    
    // -------------------------------- Static Functions -------------------------------- //
    //                                                                                    //
    //                                                                                    //
    //                                                                                    //
    //                                                                                    //
    //                                                                                    //
    // ---------------------------------------------------------------------------------- //
    
    
    // MARK: - Chụp ảnh snapshot từ UIView
    static func snapshotUI(from view: UIView) -> UIImage? {
        // Backup trạng thái góc bo
        let originalCornerRadius = view.layer.cornerRadius
        let originalMasksToBounds = view.layer.masksToBounds
        let originalClipsToBounds = view.clipsToBounds
        
        // Tạm thời bỏ bo góc
        view.layer.cornerRadius = 0
        view.layer.masksToBounds = false
        view.clipsToBounds = false
        
        // Chụp ảnh
        let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
        let image = renderer.image { context in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
        
        // Khôi phục lại trạng thái ban đầu
        view.layer.cornerRadius = originalCornerRadius
        view.layer.masksToBounds = originalMasksToBounds
        view.clipsToBounds = originalClipsToBounds
        
        return image
    }
    
    // MARK: - Tạo video từ ảnh
    static func createVideo(from image: UIImage, with audioURL: URL?, duration: Double = 10, completion: @escaping (URL?) -> Void) {
        let outputSize = image.size
        let outputURL = FileHelper.shared.fileURL(fileName: "output.mp4", in: .temp)
        
        // Xoá file cũ nếu có
        try? FileManager.default.removeItem(at: outputURL)
        
        // Khởi tạo AVAssetWriter để ghi video
        guard let writer = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
            print("⚠️ Can't create AVAssetWriter")
            completion(nil)
            return
        }
        
        // Thiết lập thông số video
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264, // Định dạng chuẩn
            AVVideoWidthKey: outputSize.width,
            AVVideoHeightKey: outputSize.height
        ]
        
        // Ghi dữ liệu video
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: nil)
        
        guard writer.canAdd(writerInput) else {
            print("⚠️ Can't add writer input")
            completion(nil)
            return
        }
        writer.add(writerInput)
        
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        
        let fps: Int32 = 1 // chỉ có 1 hình
        let frameDuration = CMTimeMake(value: 1, timescale: fps)
        let totalFrames = Int(duration * Double(fps))
        
        let queue = DispatchQueue(label: "com.nhanho.videoWriterQueue.image")
        
        writerInput.requestMediaDataWhenReady(on: queue) {
            var frameCount = 0
            while writerInput.isReadyForMoreMediaData && frameCount < totalFrames {
                let time = CMTimeMultiply(frameDuration, multiplier: Int32(frameCount))
                
                if let image = image.ciImage?.pixelBuffer {
                    adaptor.append(image, withPresentationTime: time)
                }
                
                frameCount += 1
            }
            
            writerInput.markAsFinished()
            writer.finishWriting {
                print("✅ Video was created without audio at: \(outputURL)")
                
                if let audioURL = audioURL {
                    print("⚙️ Merge audio with video...")
                    mergeAudioWithVideo(videoURL: outputURL, audioURL: audioURL) { finalURL in
                        print("✅ Video was created with audio at: \(String(describing: finalURL))")
                        completion(finalURL)
                    }
                } else {
                    completion(outputURL)
                }
            }
        }
    }
    
    // MARK: - Merge audio with video
    static func mergeAudioWithVideo(videoURL: URL, audioURL: URL, completion: @escaping (URL?) -> Void) {
        let mixComposition = AVMutableComposition()
        
        let videoAsset = AVURLAsset(url: videoURL)
        let audioAsset = AVURLAsset(url: audioURL)
        
        guard let videoTrack = videoAsset.tracks(withMediaType: .video).first,
              let compositionVideoTrack = mixComposition.addMutableTrack(withMediaType: .video,
                                                                         preferredTrackID: kCMPersistentTrackID_Invalid)
        else {
            completion(nil)
            return
        }
        
        do {
            try compositionVideoTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: videoAsset.duration),
                                                      of: videoTrack,
                                                      at: .zero)
        } catch {
            print("⚠️ Error inserting video: \(error)")
            completion(nil)
            return
        }
        
        if let audioTrack = audioAsset.tracks(withMediaType: .audio).first,
           let compositionAudioTrack = mixComposition.addMutableTrack(withMediaType: .audio,
                                                                      preferredTrackID: kCMPersistentTrackID_Invalid) {
            do {
                try compositionAudioTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: videoAsset.duration),
                                                          of: audioTrack,
                                                          at: .zero)
            } catch {
                print("⚠️ Error inserting audio: \(error)")
                completion(nil)
                return
            }
        }
        
        let finalURL = FileHelper.shared.fileURL(fileName: "final_output.mp4", in: .temp)
        try? FileManager.default.removeItem(at: finalURL)
        
        guard let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) else {
            completion(nil)
            return
        }
        
        exporter.outputURL = finalURL
        exporter.outputFileType = .mp4
        exporter.exportAsynchronously {
            switch exporter.status {
            case .completed:
                completion(finalURL)
            default:
                print("❌ Export failed: \(String(describing: exporter.error))")
                completion(nil)
            }
        }
    }
}
