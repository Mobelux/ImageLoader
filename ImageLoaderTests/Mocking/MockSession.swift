//
//  MockSession.swift
//  ImageLoader
//
//  Created by Jerry Mayers on 11/3/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import Foundation
@testable import ImageLoader

class MockSession: Session {

    private let reachable: Reachable
    private let cache: URLCache

    init(reachable: Reachable, cache: URLCache) {
        self.reachable = reachable
        self.cache = cache
    }

    func sessionDataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> SessionDataTask {
        if reachable.isReachable {
            if isRequestInCache(request: request) && (request.cachePolicy == .returnCacheDataDontLoad || request.cachePolicy == .returnCacheDataElseLoad || request.cachePolicy == .useProtocolCachePolicy) {
                return dataTaskFromCache(with: request, completionHandler: completionHandler)
            } else {
                return dataTaskFromNetwork(with: request, completionHandler: completionHandler)
            }
        } else {
            return dataTaskFromCache(with: request, completionHandler: completionHandler)
        }
    }

    private func dataTaskFromCache(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> SessionDataTask {
        let task = MockDataTask(resume: { (task) in
            guard !task.isCancelled else { return }

            guard let response = self.cache.cachedResponse(for: request) else {
                completionHandler(nil, nil, NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotFindHost, userInfo: nil))
                return
            }

            completionHandler(response.data, response.response, nil)
        }, cancel: {
            self.doCancel(completionHandler: completionHandler)
        })
        return task
    }

    private func dataTaskFromNetwork(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> SessionDataTask {
        let task = MockDataTask(resume: { (task) in
            DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + self.randomDelay(), execute: { 
                guard !task.isCancelled, let requestURL = request.url else { return }
                let data: Data?
                if let url = Bundle(for: MockSession.self).url(forResource: "mock_image", withExtension: "jpg") {
                    data = try? Data(contentsOf: url)
                } else {
                    data = nil
                }

                let response = URLResponse(url: requestURL, mimeType: "image/jpeg", expectedContentLength: data?.count ?? 0, textEncodingName: nil)

                if let data = data {
                    let cachedResponse = CachedURLResponse(response: response, data: data)
                    self.cache.storeCachedResponse(cachedResponse, for: request)
                }

                completionHandler(data, response, nil)
            })
        }, cancel: {
            self.doCancel(completionHandler: completionHandler)
        })
        return task
    }

    private func isRequestInCache(request: URLRequest) -> Bool {
        return cache.cachedResponse(for: request) != nil
    }

    private func doCancel(completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil)
        completionHandler(nil, nil, error)
    }

    private func randomDelay() -> TimeInterval {
        // Generate a random number of milliseconds between 50 and 1050
        let randomMS = arc4random_uniform(1000) + 50
        return TimeInterval(randomMS) / 1000.0
    }
}

class MockDataTask: SessionDataTask {

    private let resumeBlock: ((_ task: MockDataTask) -> Void)?
    private let cancelBlock: (() -> Void)?

    fileprivate var isCancelled: Bool = false

    fileprivate init(resume: @escaping (_ task: MockDataTask) -> Void, cancel: @escaping () -> Void) {
        self.resumeBlock = resume
        self.cancelBlock = cancel
    }

    func resume() {
        resumeBlock?(self)
    }

    func cancel() {
        isCancelled = true
        cancelBlock?()
    }
}
