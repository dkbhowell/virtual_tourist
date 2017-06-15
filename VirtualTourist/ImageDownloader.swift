//
//  ImageDownloader.swift
//  VirtualTourist
//
//  Created by Dustin Howell on 6/14/17.
//  Copyright © 2017 Dustin Howell. All rights reserved.
//

import UIKit

class ImageDownloader {
    
    weak var delegate: ImageDownloaderDelegate?
    
    func downloadImages(urls: [URL]) {
        for url in urls {
            downloadImage(url: url)
        }
    }
    
    func downloadImage(url: URL) {
        DispatchQueue.global(qos: .background).async {
            guard let data = try? Data(contentsOf: url),
                let image = UIImage(data: data) else {
                    return
            }
            executeOnMain {
                self.delegate?.downloader(self, didDownloadImage: image)
            }
        }
    }
    
}
