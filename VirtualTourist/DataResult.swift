//
//  DataResult.swift
//  VirtualTourist
//
//  Created by Dustin Howell on 6/13/17.
//  Copyright © 2017 Dustin Howell. All rights reserved.
//

import Foundation

enum DataResult<T,E: Error> {
    case success(T)
    case failure(E)
}
