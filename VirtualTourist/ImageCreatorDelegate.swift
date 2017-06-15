//
//  ImageDownloaderDelegate.swift
//  VirtualTourist
//
//  Created by Dustin Howell on 6/14/17.
//  Copyright © 2017 Dustin Howell. All rights reserved.
//

import UIKit

protocol ImageCreatorDelegate: class {
    func creator(_ creator: ImageCreator, didCreateImage image: UIImage)
}
