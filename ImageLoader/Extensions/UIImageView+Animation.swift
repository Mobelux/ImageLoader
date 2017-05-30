//
//  UIImageView+Animation.swift
//  ImageLoader
//
//  MIT License
//
//  Copyright (c) 2017 Mobelux
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

public extension UIImageView {

    /// Fades in a new image. It begins at the current state of the UIImageView, so if you want to fade from one image to the next, you should set the initial image via `imageView.image = initialImage` prior to calling this.
    ///
    /// - Parameters:
    ///   - image: The new image that should be faded in, and shown fully when the animation is complete
    ///   - duration: How long should the fade take
    ///   - completion: Called when the animation is complete. It will be called on the same queue that called this `fadeTo()` function, which you should do from the main queue.
    public func fadeTo(image: UIImage, duration: TimeInterval, completion: (() -> Void)?) {
        guard self.image != image else { return }

        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)

        let animation = CATransition()
        animation.duration = duration
        animation.type = kCATransitionFade
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        layer.add(animation, forKey: "imageTransition")

        self.image = image
        CATransaction.commit()
    }
}
