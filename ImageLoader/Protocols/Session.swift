//
//  Session.swift
//  ImageLoader
//
//  Created by Jerry Mayers on 11/3/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import Foundation

protocol Session {

    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
}

extension URLSession: Session { }
