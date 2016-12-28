//
//  GIFView.swift
//  ImageLoader
//
//  Created by Jerry Mayers on 12/28/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import UIKit

public class GIFView: UIView {
    private enum Constants {
        static let animationKey = "gif_animation"
    }

    private var reader: GIFReader?

    /// Will anything happen if you call `resumePlayback()`
    public var isAnimateableAndReadyToPlay: Bool { return animation != nil }

    /// Is an animation playing
    public var isPlaying: Bool { return layer.animation(forKey: Constants.animationKey) != nil }

    private var animation: CAKeyframeAnimation?

    public override init(frame: CGRect) {
        super.init(frame: frame)

        layer.contentsGravity = kCAGravityCenter
        layer.masksToBounds = true
        layer.actions = ["contents":NSNull()]
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var intrinsicContentSize: CGSize { return reader?.actualGIFSize ?? CGSize(width: UIViewNoIntrinsicMetric, height: UIViewNoIntrinsicMetric) }

    /// Load a GIF and prepare it for playback, and display the first frame, you must call `resumePlayback()` before it will start to play.
    ///
    /// - Parameter from: The URL to load the GIF from (should be a local file)
    /// - Parameter loopForever: Should we ignore the GIF's loop count, and loop forever?
    /// - Parameter complete: Called when loading has finished. True if successfully loaded & ready to play
    public func load(from url: URL, loopForever: Bool, complete: ((_ loaded: Bool) -> Void)?) {
        pausePlayback()
        DispatchQueue.global(qos: .default).async {
            guard var reader = GIFReader(with: url),
                let firstImage = reader.frame(at: 0)?.cgImageForceDecode() else {
                    DispatchQueue.main.async {
                        complete?(false)
                    }
                    return
            }

            // Show first static image
            DispatchQueue.main.async {
                self.invalidateIntrinsicContentSize()
                self.display(image: firstImage)
            }

            if reader.numberOfFrames > 1 {
                let frames = reader.frames.flatMap({ $0.cgImageForceDecode() })
                let delays = reader.frameDelays
                let repeatCount = loopForever ? 0 : reader.loopCount
                self.animation = self.createAnimation(for: frames, delays: delays, repeatCount: repeatCount)
            }
            self.reader = reader
            if let complete = complete {
                DispatchQueue.main.async {
                    complete(true)
                }
            }
        }
    }

    public func resumePlayback() {
        guard isAnimateableAndReadyToPlay, let animation = animation else { return }
        layer.add(animation, forKey: Constants.animationKey)
    }

    public func pausePlayback() {
        guard isPlaying else { return }

        layer.removeAnimation(forKey: Constants.animationKey)
    }

    /// Unloads the GIF, and clears any image from being displayed
    public func clearGIF() {
        pausePlayback()
        reader = nil
        animation = nil
        display(image: nil)
    }

    private func display(image: CGImage?) {
        layer.contents = image
    }

    private func createAnimation(for images: [CGImage], delays: [TimeInterval], repeatCount: Int) -> CAKeyframeAnimation {
        let totalLoopTime = delays.reduce(0, +)

        var keyTimes = [TimeInterval]()
        keyTimes.append(0)
        for (index, delay) in delays.enumerated() {
            if index > 0 {
                if let lastTime = keyTimes.last {
                    let time = lastTime + delay / totalLoopTime
                    keyTimes.append(time)
                }
            }
        }
        keyTimes.append(1)

        let animation = CAKeyframeAnimation(keyPath: "contents")
        if repeatCount == 0 {
            animation.repeatCount = HUGE
        }
        else {
            animation.repeatCount = Float(repeatCount)
        }
        animation.isRemovedOnCompletion = false
        animation.values = images
        animation.keyTimes = keyTimes as [NSNumber]?
        animation.duration = totalLoopTime
        animation.calculationMode = kCAAnimationDiscrete
        
        return animation
    }
}
