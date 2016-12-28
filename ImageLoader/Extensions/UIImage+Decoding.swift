//
//  UIImage+Decoding.swift
//  ImageLoader
//
//  Created by Jerry Mayers on 12/28/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import UIKit

public extension UIImage {

    /// Traditionally `UIImages` along with `imageInstance.cgImage` are lazy loading.
    /// This can be a problem when we are trying to delibrately load a bunch in a background quque so as to not block the main queue.
    /// This method gets around that, but forcing the `UIImage` to draw it's `cgImage` therefor loading it, on whatever queue calls this.
    ///
    /// - Returns: Ideally the decoded image, however it is possible that it was unable to force the image load. If this happens it will just return `cgImage` directly, so the returned image could possibly have not been decoded yet. However the chance of that fallback occurring is quite low.
    public func cgImageForceDecode() -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        let width = Int(size.width)
        let height = Int(size.height)

        let bitsPerComponent = 8
        let bytesPerRow = width * 4
        let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        let dataSize = bytesPerRow * height
        let bitmapData = UnsafeMutablePointer<UInt8>.allocate(capacity: dataSize)
        defer {
            bitmapData.deinitialize()
            bitmapData.deallocate(capacity: dataSize)
        }

        guard let context = CGContext(data: bitmapData, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo),
            let CGImage = cgImage else {
                return nil
        }

        context.draw(CGImage, in: CGRect(origin: CGPoint.zero, size: size))
        let outputImage = context.makeImage()
        return outputImage ?? CGImage
    }
}
