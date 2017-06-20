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
    var queues = [DispatchQueue(label: "q1"), DispatchQueue(label: "q2"), DispatchQueue(label: "q3"), DispatchQueue(label: "q4")]
    var queue: DispatchQueue {
        let randomIndex = Int(arc4random_uniform(UInt32(queues.count)))
        return queues[randomIndex]
    }
    
    func downloadImages(urls: [URL]) {
        let downloadGroup = DispatchGroup()
        for url in urls {
            downloadGroup.enter()
            queue.async {
                guard let data = try? Data(contentsOf: url),
                    let image = UIImage(data: data) else {
                        downloadGroup.leave()
                        return
                }
                downloadGroup.leave()
                executeOnMain {
                    self.delegate?.downloader(self, didDownloadImage: image)
                }
            }
        }
        downloadGroup.notify(queue: DispatchQueue.main) { 
            self.delegate?.downloader(self, didFinishDownloadingImages: true)
        }
    }
    
    func downloadImage(url: URL) {
        queue.async {
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
