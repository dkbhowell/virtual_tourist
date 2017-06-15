//
//  ImageDownloaderDelegate.swift
//  VirtualTourist
//
//  Created by Dustin Howell on 6/14/17.
//  Copyright © 2017 Dustin Howell. All rights reserved.
//

import UIKit

protocol ImageDownloaderDelegate: class {
    func downloader(_ downloader: ImageDownloader, didDownloadImage image: UIImage)
}
