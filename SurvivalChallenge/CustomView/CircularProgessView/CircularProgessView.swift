//
//  CircularProgessView.swift
//  SurvivalChallenge
//
//  Created by Apple on 28/4/25.
//

import Foundation
import UIKit

class CircularProgressView: UIView, CAAnimationDelegate {
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    private let progressLayer = CAShapeLayer()
    private let centerShapeView = UIView()
    var isPaused = false
    private var pauseMarkers = [CAShapeLayer]()
    
    private var duration: TimeInterval = 0
    private var pausedProgressValues: [CGFloat] = []
    private var recordedDurations: [Double] = []
    private var currentTimeInSeconds: Double = 0.0
    var onCompletion: (() -> Void)?
    var onPause: ((Bool) -> Void)?
    var onReset: (() -> Void)?
    var onTimeUpdated: ((CGFloat) -> Void)?
    
    deinit {
        print("⚙️ deinit \(Self.self)")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        blurView.frame = bounds
        blurView.layer.cornerRadius = bounds.width / 2
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = (min(bounds.width, bounds.height) - progressLayer.lineWidth) / 2
        let path = UIBezierPath(arcCenter: center,
                                radius: radius,
                                startAngle: -.pi / 2,
                                endAngle: 1.5 * .pi,
                                clockwise: true)
        progressLayer.path = path.cgPath
        progressLayer.frame = bounds
        
        // Layout red square
        if centerShapeView.bounds == .zero {
            centerShapeView.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
            centerShapeView.center = center
            centerShapeView.layer.cornerRadius = 8
        }
    }

    private func setupView() {
        blurView.clipsToBounds = true
        blurView.layer.cornerRadius = bounds.width / 2
        addSubview(blurView)
        
        progressLayer.strokeColor = UIColor.red.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = 5
        progressLayer.strokeStart = 0
        progressLayer.strokeEnd = 0
        layer.addSublayer(progressLayer)
        
        centerShapeView.backgroundColor = .red
        centerShapeView.layer.cornerRadius = 8
        centerShapeView.clipsToBounds = true
        addSubview(centerShapeView)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.addGestureRecognizer(tap)
    }
    
    @objc func handleTap() {
        let currentProgress = progressLayer.presentation()?.strokeEnd ?? progressLayer.strokeEnd
        
        if currentProgress >= 0.99999 {
            print("⚙️ Progress reached the limit")
            let alert = UIAlertController(title: Localized.Camera.progressReachedTheLimit, message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            if let topVC = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?
                .rootViewController {
                
                topVC.present(alert, animated: true)
            }
            return
        }
        
        self.pauseProgress()
    }
    
    func pauseProgress() {
        if isPaused {
            resumeAnimation()
            shrinkToSquare()
        } else {
            pauseAnimation()
            addPauseMarker()
            expandToCircle()
        }
        isPaused.toggle()
        onPause?(isPaused)
    }
    
    func startProgress(duration: TimeInterval) {
        self.duration = duration
        self.isPaused = false
        
        // Clear any existing pause markers
        for marker in pauseMarkers {
            marker.removeFromSuperlayer()
        }
        pauseMarkers.removeAll()
        
        progressLayer.strokeEnd = 0
        progressLayer.removeAllAnimations()
        
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.toValue = 1
        animation.duration = duration
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        animation.delegate = self
        progressLayer.add(animation, forKey: "progress")
        
        shrinkToSquare()
    }

    private func addPauseMarker() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = (min(bounds.width, bounds.height) - progressLayer.lineWidth) / 2

        let lastProgressValue = pausedProgressValues.last ?? progressLayer.strokeEnd
        
        let startAngle: CGFloat = -.pi / 2
        let progressAngle = startAngle + (lastProgressValue * 2 * .pi)
        
        let markerLayer = CAShapeLayer()
        markerLayer.strokeColor = UIColor.white.cgColor
        markerLayer.lineWidth = 2
        markerLayer.lineCap = .round
        
        let innerPoint = CGPoint(
            x: center.x + (radius - progressLayer.lineWidth/4) * cos(progressAngle),
            y: center.y + (radius - progressLayer.lineWidth/4) * sin(progressAngle)
        )
        let outerPoint = CGPoint(
            x: center.x + (radius + progressLayer.lineWidth/4) * cos(progressAngle),
            y: center.y + (radius + progressLayer.lineWidth/4) * sin(progressAngle)
        )
        
        let path = UIBezierPath()
        path.move(to: innerPoint)
        path.addLine(to: outerPoint)
        
        markerLayer.path = path.cgPath
        
        layer.addSublayer(markerLayer)
        pauseMarkers.append(markerLayer)
        
        let segmentDuration: Double
        if recordedDurations.isEmpty {
            segmentDuration = duration * lastProgressValue
        } else {
            let segmentEnd = duration * lastProgressValue
            let segmentStart = recordedDurations.last ?? 0
            segmentDuration = segmentEnd - segmentStart
        }
        recordedDurations.append(segmentDuration)
    }
    
    func discardLastSegment() {
        guard !pauseMarkers.isEmpty else {
            return
        }
        
        if pauseMarkers.count == 1 {
            let lastMarker = pauseMarkers.removeLast()
            lastMarker.removeFromSuperlayer()
            
            progressLayer.removeAllAnimations()
            let currentProgress = progressLayer.presentation()?.strokeEnd ?? progressLayer.strokeEnd
            
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = currentProgress
            animation.toValue = 0
            animation.duration = 0.25
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            
            progressLayer.add(animation, forKey: "resetToZero")
            
            _ = recordedDurations.popLast()
            
            currentTimeInSeconds = 0.0
            onTimeUpdated?(currentTimeInSeconds)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.progressLayer.strokeEnd = 0
                self.pausedProgressValues = [0]
                self.onReset?()
            }
            
            return
        }

        let lastMarker = pauseMarkers.removeLast()
        lastMarker.removeFromSuperlayer()

        let currentProgress = pausedProgressValues.removeLast()
        let previousProgress = pausedProgressValues.last ?? 0

        progressLayer.removeAllAnimations()
        progressLayer.strokeEnd = currentProgress

        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = currentProgress
        animation.toValue = previousProgress
        animation.duration = 0.25
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        progressLayer.add(animation, forKey: "reverseProgress")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.progressLayer.strokeEnd = previousProgress
        }
        
        _ = recordedDurations.popLast()
        
        currentTimeInSeconds = recordedDurations.reduce(0, +)
        onTimeUpdated?(currentTimeInSeconds)
    }
    
    func discardAllSegment() {
        for marker in pauseMarkers {
            marker.removeFromSuperlayer()
        }
        pauseMarkers.removeAll()
        
        progressLayer.removeAllAnimations()
        
        let currentProgress = progressLayer.presentation()?.strokeEnd ?? progressLayer.strokeEnd
        
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = currentProgress
        animation.toValue = 0
        animation.duration = 0.25
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        progressLayer.add(animation, forKey: "resetToZero")
        
        pausedProgressValues = [0]
        recordedDurations.removeAll()
        currentTimeInSeconds = 0.0
        
        onTimeUpdated?(currentTimeInSeconds)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.progressLayer.strokeEnd = 0
            self.onReset?()
        }
    }

    private func expandToCircle() {
        UIView.animate(withDuration: 0.25) {
            self.centerShapeView.frame = CGRect(x: 0, y: 0, width: 62, height: 62)
            self.centerShapeView.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
            self.centerShapeView.layer.cornerRadius = 31
        }
    }

    private func shrinkToSquare() {
        UIView.animate(withDuration: 0.25) {
            self.centerShapeView.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
            self.centerShapeView.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
            self.centerShapeView.layer.cornerRadius = 8
        }
    }

    private func pauseAnimation() {
        let currentProgress: CGFloat
        if let presentation = progressLayer.presentation() {
            currentProgress = presentation.strokeEnd
        } else {
            currentProgress = progressLayer.strokeEnd
        }

        pausedProgressValues.append(currentProgress)
        
        progressLayer.removeAllAnimations()
        progressLayer.strokeEnd = currentProgress
    }

    private func resumeAnimation() {
        guard let lastProgress = pausedProgressValues.last else { return }

        let remainingProgress = 1.0 - lastProgress
        let remainingDuration = duration * remainingProgress

        progressLayer.removeAllAnimations()

        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = lastProgress
        animation.toValue = 1
        animation.duration = remainingDuration
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        animation.delegate = self
        progressLayer.add(animation, forKey: "progress")
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag {
            isPaused = true
            
            expandToCircle()
            pauseAnimation()
            addPauseMarker()
            
            onCompletion?()
        }
    }
}
