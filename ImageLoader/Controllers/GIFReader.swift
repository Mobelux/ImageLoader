//
//  GIFReader.swift
//  ImageLoader
//
//  Created by Jerry Mayers on 12/28/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import ImageIO
import UIKit

public struct GIFReader {
    private enum Constants {
        // Some GIFs don't have a frame delay and rely on renders having a default. This default matches Safari
        static let defaultFrameDelay: TimeInterval = 0.1
        // Delay smaller then this isn't realistically playable on a device
        static let minimumFrameDelay: TimeInterval = 0.01
    }

    /// If loop count can't be determined then it will be Int.max
    public let loopCount: Int

    /// Total number of frames in the GIF
    public let numberOfFrames: Int

    /// The delay for each frame
    public let frameDelays: [TimeInterval]

    /// True if all values of `frameDelays` are equal
    public let areAllFrameDelaysTheSame: Bool

    /// The average of all the values in `frameDelays`
    public let averageFrameDelay: TimeInterval

    /// All the frames in the GIF. They are lazy loaded, so if you don't need all, then you should use `frame(at:)` instead
    public lazy var frames: [UIImage] = {
        var allFrames = [UIImage]()
        for index in 0..<self.numberOfFrames {
            if let frame = self.frame(at: index) {
                allFrames.append(frame)
            }
        }
        return allFrames
    }()

    /// The size reported in the metadata.
    public let reportedGIFSize: CGSize?

    /// The actual size of the first frame of the GIF. Accessing this requires loading the first frame, and will be `CGSize.zero` if unable to load
    public lazy var actualGIFSize: CGSize = {
        let firstFrame = self.frame(at: 0)
        return firstFrame?.size ?? .zero
    }()

    // MARK: Private
    private let url: URL
    private var imageSource: CGImageSource
    private var allFrames: [UIImage]?

    public init?(with url: URL) {
        self.url = url
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        imageSource = source

        loopCount = GIFReader.loopCount(for: imageSource)
        numberOfFrames = CGImageSourceGetCount(imageSource)
        frameDelays = GIFReader.allFrameDelays(from: imageSource)
        areAllFrameDelaysTheSame = Set(frameDelays).count == 1
        averageFrameDelay = frameDelays.reduce(0, +) / TimeInterval(frameDelays.count)
        reportedGIFSize = GIFReader.reportedGIFSize(for: imageSource)
    }

    public mutating func frame(at index: Int) -> UIImage? {
        guard index < numberOfFrames else { return nil }
        // Sometimes when reading frames when the app is backgrounded &| device is sleeping the status at an index will become kCGImageStatusIncomplete & kCGImageStatusUnknownType. It appears that kCGImageStatusIncomplete doesn't cause any problems, but when the status is kCGImageStatusUnknownType then CGImageSourceCreateImageAtIndex will crash the app. So to be safe we try to recreate the source when these statuses occur. I tried to just return a nil image, but then when the user resumes the app, the source is still stuck in this funky state and never resumes. So we recreate the bad source.
        if CGImageSourceGetStatus(imageSource) != .statusComplete || CGImageSourceGetStatusAtIndex(imageSource, index) != .statusComplete {
            recreateImageSource()
        }

        guard CGImageSourceGetStatus(imageSource) == .statusComplete && CGImageSourceGetStatusAtIndex(imageSource, index) == .statusComplete else { return nil }

        let options: NSDictionary = [kCGImageSourceShouldCache : true]
        if let image = CGImageSourceCreateImageAtIndex(imageSource, index, options) {
            return UIImage(cgImage: image)
        } else {
            return nil
        }
    }

    // MARK: - Private
    private mutating func recreateImageSource() {
        if let source = CGImageSourceCreateWithURL(url as CFURL, nil) {
            imageSource = source
        }
    }

    private static func gifProperties(from properties: NSDictionary) -> NSDictionary? {
        return properties[kCGImagePropertyGIFDictionary as NSString] as? NSDictionary
    }

    private static func frameProperties(for index: Int, imageSource: CGImageSource) -> NSDictionary? {
        return CGImageSourceCopyPropertiesAtIndex(imageSource, index, nil)
    }

    private static func loopCount(for imageSource: CGImageSource) -> Int {
        guard let properties = CGImageSourceCopyProperties(imageSource, nil) as? NSDictionary,
            let gifProperties = self.gifProperties(from: properties) else { return Int.max }
        let loopCount = gifProperties[kCGImagePropertyGIFLoopCount as NSString] as? Int
        return loopCount ?? Int.max
    }

    private static func reportedGIFSize(for imageSource: CGImageSource) -> CGSize? {
        guard let properties = frameProperties(for: 0, imageSource: imageSource),
            let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
            let height = properties[kCGImagePropertyPixelHeight] as? CGFloat else { return nil }

        return CGSize(width: width, height: height)
    }

    private static func frameDelay(for index: Int, imageSource: CGImageSource) -> TimeInterval {
        guard let frameProperties = frameProperties(for: index, imageSource: imageSource),
            let frameGIFProperties = gifProperties(from: frameProperties) else { return Constants.defaultFrameDelay }

        // Follow WebKit's convention of prefering unclamped delay over delay, and use 0.1 if neither is found or if either is < 0.01 (100 FPS +) since devices can't display 100 FPS + GIFs.

        let unclampedFrameDelay = frameGIFProperties[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval
        let clampedFrameDelay = frameGIFProperties[kCGImagePropertyGIFDelayTime] as? TimeInterval

        let frameDelay = unclampedFrameDelay ?? clampedFrameDelay
        if let frameDelay = frameDelay {
            if frameDelay < Constants.minimumFrameDelay {
                return Constants.defaultFrameDelay
            } else {
                return frameDelay
            }
        } else {
            return Constants.defaultFrameDelay
        }
    }

    private static func allFrameDelays(from imageSource: CGImageSource) -> [TimeInterval] {
        let numberOfFrames = CGImageSourceGetCount(imageSource)
        var frameDelays = [TimeInterval]()
        for index in 0..<numberOfFrames {
            frameDelays.append(frameDelay(for: index, imageSource: imageSource))
        }
        return frameDelays
    }
}
