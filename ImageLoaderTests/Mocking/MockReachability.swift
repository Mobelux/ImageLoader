//
//  MockReachability.swift
//  ImageLoader
//
//  Created by Jerry Mayers on 11/3/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import Foundation
@testable import ImageLoader

class MockReachability: Reachable {
    var isReachable: Bool

    init () {
        isReachable = true
    }
}
