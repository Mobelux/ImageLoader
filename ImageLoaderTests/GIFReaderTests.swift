//
//  GIFReaderTests.swift
//  ImageLoader
//
//  Created by Jerry Mayers on 12/28/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import XCTest
import ImageLoader

class GIFReaderTests: XCTestCase {

    func testBasicReader() {
        let url = Bundle(for: GIFReaderTests.self).url(forResource: "premade", withExtension: "gif")!
        let optionalReader = GIFReader(with: url)
        XCTAssertNotNil(optionalReader, "Couldn't create the reader")
        guard var reader = optionalReader else { return }
        XCTAssert(reader.numberOfFrames == 30, "Frame count incorrect")
        XCTAssertNotNil(reader.frame(at: 0), "Can't load frame")
        XCTAssert(reader.areAllFrameDelaysTheSame, "Frame delays should be the same")
        XCTAssertEqualWithAccuracy(reader.averageFrameDelay, 0.1, accuracy: 0.0000001, "The average frame delay is incorrect")
        XCTAssert(reader.loopCount == 0, "loop count incorrect")
        XCTAssert(reader.actualGIFSize != .zero, "Actual size was zero")
        XCTAssert(reader.actualGIFSize == reader.reportedGIFSize!, "Sizes differ")
        XCTAssert(reader.frameDelays.count == reader.numberOfFrames, "The number of delays doesn't match the number of frames")
    }

    func test33FPSReader() {
        let url = Bundle(for: GIFReaderTests.self).url(forResource: "33fps", withExtension: "gif")!
        let optionalReader = GIFReader(with: url)
        XCTAssertNotNil(optionalReader, "Couldn't create the reader")
        guard let reader = optionalReader else { return }
        XCTAssertEqualWithAccuracy(reader.averageFrameDelay, 0.03, accuracy: 0.0001, "The average frame delay is incorrect")
    }

    func testFrameDelayCountMismatch() {
        let url = Bundle(for: GIFReaderTests.self).url(forResource: "missing_every_other_delay", withExtension: "gif")!
        let optionalReader = GIFReader(with: url)
        XCTAssertNotNil(optionalReader, "Couldn't create the reader")
        guard let reader = optionalReader else { return }
        XCTAssert(reader.frameDelays.count == reader.numberOfFrames, "The number of delays doesn't match the number of frames")
    }

    func testAllFrameDelaysMissing() {
        let url = Bundle(for: GIFReaderTests.self).url(forResource: "missing_all_delays", withExtension: "gif")!
        let optionalReader = GIFReader(with: url)
        XCTAssertNotNil(optionalReader, "Couldn't create the reader")
        guard let reader = optionalReader else { return }
        XCTAssert(reader.frameDelays.count == reader.numberOfFrames, "The number of delays doesn't match the number of frames")
        for delay in reader.frameDelays {
            XCTAssertEqualWithAccuracy(delay, 0.1, accuracy: 0.0000001, "We should be using 0.1 as the default when a frame delay is missing")
        }
    }

    func testVariableFrameDelay() {
        let url = Bundle(for: GIFReaderTests.self).url(forResource: "variable_frame_delay", withExtension: "gif")!
        let optionalReader = GIFReader(with: url)
        XCTAssertNotNil(optionalReader, "Couldn't create the reader")
        guard let reader = optionalReader else { return }
        XCTAssertFalse(reader.areAllFrameDelaysTheSame, "All framea are reporting the same delay, this is wrong")
        XCTAssertEqualWithAccuracy(reader.averageFrameDelay, 0.10078, accuracy: 0.00001, "Average frame delay is incorrect")
    }
}
