//
//  Reachable.swift
//  ImageLoader
//
//  Created by Jerry Mayers on 11/3/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import Foundation

protocol Reachable {

    /// Can this device reach the internet via any means?
    var isReachable: Bool { get }
}
