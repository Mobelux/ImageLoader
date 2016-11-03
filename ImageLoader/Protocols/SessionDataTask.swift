//
//  SessionDataTask.swift
//  ImageLoader
//
//  Created by Jerry Mayers on 11/3/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import Foundation

protocol SessionDataTask {
    func resume()
    func cancel()
}

extension URLSessionDataTask: SessionDataTask { }
