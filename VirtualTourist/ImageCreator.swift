//
//  ImageCreator.swift
//  VirtualTourist
//
//  Created by Dustin Howell on 6/15/17.
//  Copyright © 2017 Dustin Howell. All rights reserved.
//

import UIKit

class ImageCreator {
    
    weak var delegate: ImageCreatorDelegate?
    
    func createImages(data: [Data]) {
        for imageData in data {
            createImage(data: imageData)
        }
    }
    
    func createImage(data: Data) {
        DispatchQueue.global(qos: .background).async {
            guard let image = UIImage(data: data) else {
                return
            }
            executeOnMain {
                self.delegate?.creator(self, didCreateImage: image)
            }
        }
    }
    
}
