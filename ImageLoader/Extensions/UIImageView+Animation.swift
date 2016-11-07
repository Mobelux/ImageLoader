//
//  UIImageView+Animation.swift
//  ImageLoader
//
//  Created by Jerry Mayers on 11/4/16.
//  Copyright © 2016 Mobelux. All rights reserved.
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
