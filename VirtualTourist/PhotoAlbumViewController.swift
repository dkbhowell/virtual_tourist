//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Dustin Howell on 6/13/17.
//  Copyright © 2017 Dustin Howell. All rights reserved.
//

import UIKit
import MapKit

class PhotoAlbumViewController: UIViewController {
    
    // MARK: Constants
    private let maxPhotos = 100
    
    // MARK: Properties
    var pin: MapPin!
    var imageUrls = [URL]() {
        didSet {
            print("Reloading collection view from imageUrl didSet")
            executeOnMain {
                self.collectionView.reloadData()
            }
        }
    }
    var images = [UIImage]() {
        didSet {
            imagesAvailable = true
            executeOnMain {
                print("Reloading collection view from images didSet")
                self.collectionView.reloadData()
            }
        }
    }
    
    var imagesAvailable = false
    
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = false
        collectionView.dataSource = self
        
        print("Selecting pin")
        mapView.addAnnotation(pin)
        mapView.showAnnotations([pin], animated: true)
        
        let flickrClient = FlickrClient.shared
        flickrClient.photoSearch(latitude: pin.coordinate.latitude, longitude: pin.coordinate.longitude) { (result) in
            switch result {
            case .success(let urls):
                print("Successfully retreived \(urls.count) image URLs")
                self.imageUrls = urls
                self.images = self.downloadImages(urls: urls, maxCount: self.maxPhotos)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    // MARK: Helper Methods
    
    private func downloadImages(urls: [URL], maxCount: Int? = nil) -> [UIImage] {
        var images = [UIImage]()
        var count = 0
        for url in urls {
            let data = try? Data(contentsOf: url)
            guard let imageData = data else {
                continue
            }
            let imageOpt = UIImage(data: imageData)
            guard let image = imageOpt else {
                continue
            }
            images.append(image)
            count += 1
            if let max = maxCount, count >= max  {
                break
            }
        }
        print("retrieved \(images.count) images")
        return images
    }

}


extension PhotoAlbumViewController: UICollectionViewDataSource {
    var cellReuseIdentefier: String { return "photoCell" }
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = imagesAvailable ? images.count : imageUrls.count
        print("numberOfItemsInSection: \(count)")
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentefier, for: indexPath) as! ImageCollectionViewCell
        cell.backgroundColor = UIColor.lightGray
        
        if imagesAvailable {
            let image = images[indexPath.row]
            cell.configureWithImage(image: image)
        } else {
            cell.configureWithImage(image: nil)
        }
        return cell
    }
}
