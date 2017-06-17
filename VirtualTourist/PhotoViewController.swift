//
//  PhotoViewController.swift
//  VirtualTourist
//
//  Created by Dustin Howell on 6/16/17.
//  Copyright © 2017 Dustin Howell. All rights reserved.
//

import UIKit

class PhotoViewController: UIViewController {
    
    // MARK: Properties
    var photo: Photo!
    
    // MARK: Outlets
    @IBOutlet weak var imageView: UIImageView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let imageData = (photo.image as Data?), let image = UIImage(data: imageData) else {
            print("No Image to Display")
            return
        }
        
        imageView.image = image
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = false
    }

}
