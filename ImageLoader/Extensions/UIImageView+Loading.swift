//
//  UIImageView+Loading.swift
//  ImageLoader
//
//  Created by Jerry Mayers on 11/4/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import UIKit

private let loadingImageViews: NSMapTable = NSMapTable<UIImageView, TaskBox>(keyOptions: .weakMemory, valueOptions: .strongMemory)

private class TaskBox {
    var task: ImageLoader.LoadingTask
    init(task: ImageLoader.LoadingTask) {
        self.task = task
    }
}

public extension UIImageView {
    private enum Constants {
        static let imageFadeDuration: TimeInterval = 0.3
    }

    /// Loads an image from a server using `ImageLoader`. When the image is loaded it will be shown in this view. If the image load completes and came from the cache, we will just show the image immediately. This is because cache loads should be near instant. But if the image is downloaded, then we will fade the image in, gradually replacing this view's current `image`.
    ///
    /// - Parameters:
    ///   - imageURL: The URL to the image to load
    ///   - fadeFromNetwork: Should images that are from the network (not cached) be faded in
    ///   - renderingMode: Should the image use a specific rendering mode. The default value is `automatic`
    ///   - loader: The image loader instance to use. If none is given then the shared loader will be used
    ///   - completion: Called once the load & fade animation is finished. `success` will be `true` if we were able to load the requested image.
    public func load(imageURL: URL, fadeFromNetwork fade: Bool = true, renderingMode: UIImageRenderingMode = .automatic, loader: ImageLoader = ImageLoader.shared, completion: ((_ success: Bool) -> Void)? = nil) {
        cancelImageLoad()

        let task = loader.image(from: imageURL) { (image, fromCache) in
            loadingImageViews.removeObject(forKey: self)

            guard let image = image?.withRenderingMode(renderingMode) else {
                completion?(false)
                return
            }


            if fromCache || !fade {
                self.image = image
                completion?(true)
            } else {
                self.fadeTo(image: image, duration: Constants.imageFadeDuration, completion: {
                    completion?(true)
                })
            }
        }

        let taskBox = TaskBox(task: task)
        loadingImageViews.setObject(taskBox, forKey: self)
    }

    /// Cancels any image loading for this image view. If the image view is in a table/collection view cell/header you should call this in `prepareForReuse()`. It is called automatically when you start loading a new image on this view using the `load(imageURL:completion:)` method, so no need to call it just prior to calling that.
    public func cancelImageLoad() {
        guard let taskBox = loadingImageViews.object(forKey: self) else { return }
        taskBox.task.cancel()
        loadingImageViews.removeObject(forKey: self)
    }
}
