//
//  Collection+.swift
//  VirtualTourist
//
//  Created by Dustin Howell on 6/15/17.
//  Copyright © 2017 Dustin Howell. All rights reserved.
//

import Foundation

extension Collection where Indices.Iterator.Element == Index {
    subscript (safe index: Index) -> Generator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
