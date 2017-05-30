//
//  ImageViewTests.swift
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

import XCTest
@testable import ImageLoader

class ImageViewTests: XCTestCase {

    private var cache: URLCache?

    override func setUp() {
        super.setUp()
        cache?.removeAllCachedResponses()
    }

    override func tearDown() {
        cache?.removeAllCachedResponses()
        super.tearDown()
    }

    private func configureLoader() -> (ImageLoader, Session, MockReachability) {
        let reachable = MockReachability()
        let cache = URLCache(memoryCapacity: 100 * 1024 * 1024, diskCapacity: 0, diskPath: nil)
        self.cache = cache
        let session = MockSession(reachable: reachable, cache: cache)
        let loader = ImageLoader(session: session, cache: cache, reachable: reachable)
        return (loader, session, reachable)
    }

    private func getImages() -> (mobelux: UIImage, blank: UIImage) {
        let blankImage = UIImage()
        let mobeluxURL = Bundle(for: ImageViewTests.self).url(forResource: "mobelux", withExtension: "png")!
        let mobeluxImage = UIImage(contentsOfFile: mobeluxURL.path)!
        return (mobeluxImage, blankImage)
    }

    func testImageAnimation() {
        let (mobelux, blank) = getImages()

        let view = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.image = blank

        XCTAssert(view.image == blank, "Blank image not loaded")

        let fadeExpectation = expectation(description: "Image fade in")

        view.fadeTo(image: mobelux, duration: 0.2) {
            XCTAssert(view.image == mobelux, "Mobelux image not loaded")

            fadeExpectation.fulfill()
        }

        waitForExpectations(timeout: 4, handler: nil)
    }

    func testImageLoading() {
        let (loader, _, _) = configureLoader()

        let imageURL = URL(string: "http://mobelux.com/static/img/mobelux-mark.99537226e971.png")!
        let imageExpection = expectation(description: "Image loading")

        let view = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.load(imageURL: imageURL, loader: loader) { (success) in
            XCTAssert(success, "Didn't load the image")
            XCTAssertNotNil(view.image, "Didn't load the image")

            imageExpection.fulfill()
        }

        waitForExpectations(timeout: 4, handler: nil)
    }

    func testImageLoadingNoNetwork() {
        let (loader, _, reachable) = configureLoader()

        reachable.isReachable = false

        let imageURL = URL(string: "http://mobelux.com/static/img/mobelux-mark.99537226e971.png")!
        let imageExpection = expectation(description: "Image loading")

        let view = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.load(imageURL: imageURL, loader: loader) { (success) in
            XCTAssertFalse(success, "We shouldn't be able to load the image when we can't reach the network")
            XCTAssertNil(view.image, "We shouldn't be able to load the image when we can't reach the network")

            imageExpection.fulfill()
        }

        waitForExpectations(timeout: 4, handler: nil)
    }

    func testImageLoadingCancelation() {
        let (loader, _, _) = configureLoader()

        let imageURL = URL(string: "http://mobelux.com/static/img/mobelux-mark.99537226e971.png")!
        let imageExpection = expectation(description: "Image loading")

        let view = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.load(imageURL: imageURL, loader: loader) { (success) in
            XCTAssert(false, "We should never get here")
        }
        view.cancelImageLoad()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            imageExpection.fulfill()
        }

        waitForExpectations(timeout: 4, handler: nil)
    }

    func testImageDefaultRenderingMode() {
        let (loader, _, _) = configureLoader()

        let imageURL = URL(string: "http://mobelux.com/static/img/mobelux-mark.99537226e971.png")!
        let imageExpection = expectation(description: "Image loading")

        let view = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.load(imageURL: imageURL, loader: loader) { (success) in
            XCTAssert(success, "Didn't load the image")
            XCTAssertNotNil(view.image, "Didn't load the image")
            if let image = view.image {
                XCTAssert(image.renderingMode == .automatic, "Default rendering mode incorrect")
            }

            imageExpection.fulfill()
        }

        waitForExpectations(timeout: 4, handler: nil)
    }

    func testImageOriginalRenderingMode() {
        let (loader, _, _) = configureLoader()

        let imageURL = URL(string: "http://mobelux.com/static/img/mobelux-mark.99537226e971.png")!
        let imageExpection = expectation(description: "Image loading")

        let view = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.load(imageURL: imageURL, renderingMode: .alwaysOriginal, loader: loader) { (success) in
            XCTAssert(success, "Didn't load the image")
            XCTAssertNotNil(view.image, "Didn't load the image")
            if let image = view.image {
                XCTAssert(image.renderingMode == .alwaysOriginal, "Original rendering mode incorrect")
            }

            imageExpection.fulfill()
        }

        waitForExpectations(timeout: 4, handler: nil)
    }

    func testImageTemplateRenderingMode() {
        let (loader, _, _) = configureLoader()

        let imageURL = URL(string: "http://mobelux.com/static/img/mobelux-mark.99537226e971.png")!
        let imageExpection = expectation(description: "Image loading")

        let view = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.load(imageURL: imageURL, renderingMode: .alwaysTemplate, loader: loader) { (success) in
            XCTAssert(success, "Didn't load the image")
            XCTAssertNotNil(view.image, "Didn't load the image")
            if let image = view.image {
                XCTAssert(image.renderingMode == .alwaysTemplate, "Template rendering mode incorrect")
            }

            imageExpection.fulfill()
        }

        waitForExpectations(timeout: 4, handler: nil)
    }
}
