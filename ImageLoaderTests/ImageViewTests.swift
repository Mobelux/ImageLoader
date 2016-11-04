//
//  ImageViewTests.swift
//  ImageLoader
//
//  Created by Jerry Mayers on 11/4/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import XCTest
@testable import ImageLoader

class ImageViewTests: XCTestCase {

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

}
