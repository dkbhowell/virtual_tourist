//
//  AppError.swift
//  VirtualTourist
//
//  Created by Dustin Howell on 6/13/17.
//  Copyright © 2017 Dustin Howell. All rights reserved.
//

import Foundation

enum AppError: Error, CustomStringConvertible {
    case NetworkError(domain: String, description: String)
    case UnexpectedResult(domain: String, description: String)
    
    var description: String {
        switch self {
        case .NetworkError(let domain, let desc):
            return "Network Error: \n--Domain: \(domain) \n--Description: \(desc)"
        case .UnexpectedResult(let domain, let desc):
            return "Unexpected Result: \n--Domain: \(domain) \n--Description: \(desc)"
        }
    }
}
