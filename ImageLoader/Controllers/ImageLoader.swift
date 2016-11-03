//
//  ImageLoader.swift
//  ImageLoader
//
//  Created by Jerry Mayers on 11/2/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import Foundation

public class ImageLoader {
    private enum Constants {
        static let timeoutInterval: TimeInterval = 60

        // URLSesson won't put things into the cache (memory or disk) if they are > then 5% of the total cache size
        static let memoryCacheSizeMB = 25 * 1024 * 1024
        static let diskCacheSizeMB = 250 * 1024 * 1024
    }

    /// The cache policy to use for an image request.
    /// NOTE: If the device can't reach the internet, the cached image's headers will be ignored and we will return a stale image from the cache (if it exists) no matter the policy specified
    ///
    /// - useCacheIfValid: If the image is in the cache & the cache headers say the image is valid, then use the cache. Else load from server
    /// - forceReload: Forces a reload from the server
    public enum CachePolicy {
        case useCacheIfValid
        case forceReload
    }

    /// Task that allows cancelling of an image load
    public struct LoadingTask {
        /// The URL of the image that is being loaded
        public let url: URL
        private let task: URLSessionDataTask
        /// Has this task been cancelled
        public private(set) var cancelled: Bool = false

        /// Cancel this image load
        public mutating func cancel() {
            guard !cancelled else { return }
            task.cancel()
            cancelled = true
        }

        fileprivate init(url: URL, task: URLSessionDataTask) {
            self.url = url
            self.task = task
        }
    }

    public typealias Complete = (_ image: UIImage?, _ fromCache: Bool) -> Void

    static let cache: URLCache = URLCache(memoryCapacity: Constants.memoryCacheSizeMB, diskCapacity: Constants.diskCacheSizeMB, diskPath: "ImageLoader")

    static let sessionConfiguration: URLSessionConfiguration = {
        var configuration = URLSessionConfiguration.default
        configuration.allowsCellularAccess = true
        configuration.httpMaximumConnectionsPerHost = 6
        configuration.urlCache = cache
        return configuration
    }()

    public static let shared: ImageLoader = {
        let session = URLSession(configuration: sessionConfiguration)
        let reachable = Reachability()
        return ImageLoader(session: session, cache: cache, reachable: reachable)
    }()

    private let session: URLSession
    private let cache: URLCache
    private let reachable: Reachable

    init(session: URLSession, cache: URLCache, reachable: Reachable) {
        self.session = session
        self.cache = cache
        self.reachable = reachable
    }

    /// Load an image
    ///
    /// - Parameters:
    ///   - url: The URL of the image to load
    ///   - cachePolicy: How to use the cache
    ///   - complete: Called on the main queue once the load completes (not called when the task was cancelled).
    /// - Returns: A `LoadingTask` that you can use to cancel the load at a later time
    public func image(from url: URL, cachePolicy: CachePolicy = .useCacheIfValid, complete: @escaping Complete) -> LoadingTask {

        let requestCachePolicy = self.cachePolicy(cachePolicy)
        var request = URLRequest(url: url, cachePolicy: requestCachePolicy, timeoutInterval: Constants.timeoutInterval)
        request.httpMethod = "GET"

        let cachedResponse = cache.cachedResponse(for: request)

        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error as? NSError, error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    complete(nil, false)
                }
                return
            }

            // Future optimization would be to force image decompression while still on the background queue
            // Once we do that, it may be worth using the disk cache for the Data, but use a LRU memory cache for the decompressed image
            let image = UIImage(data: data)

            let fromCache: Bool
            if let cachedResponse = cachedResponse {
                fromCache = cachedResponse.data == data
            } else {
                fromCache = false
            }

            DispatchQueue.main.async {
                complete(image, fromCache)
            }
        }

        task.resume()
        return LoadingTask(url: url, task: task)
    }

    private func cachePolicy(_ cachePolicy: CachePolicy) -> URLRequest.CachePolicy {
        let requestCachePolicy: URLRequest.CachePolicy

        if reachable.isReachable {
            switch cachePolicy {
            case .forceReload:
                requestCachePolicy = .reloadRevalidatingCacheData
            case .useCacheIfValid:
                requestCachePolicy = .useProtocolCachePolicy
            }
        } else {
            // By using this policy if we aren't able to hit the server, we will force the system to used even expired cache data. Better to display a stale image then nothing if we can't connect
            requestCachePolicy = .returnCacheDataElseLoad
        }

        return requestCachePolicy
    }
}
