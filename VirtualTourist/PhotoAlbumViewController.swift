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
            useUrlCountForPlaceholder = false
            executeOnMain {
                print("Reloading collection view from images didSet")
                self.removeAllActivityIndicators()
                self.collectionView.reloadData()
            }
        }
    }
    var useUrlCountForPlaceholder = true
    
    var activityIndicators = [UIActivityIndicatorView]()
    
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
                self.images = self.downloadImages(urls: urls)
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
        let count = useUrlCountForPlaceholder ? imageUrls.count : images.count
        print("numberOfItemsInSection: \(count)")
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentefier, for: indexPath) as! ImageCollectionViewCell
        cell.backgroundColor = UIColor.lightGray
        
        if useUrlCountForPlaceholder {
            cell.imageView.image = nil
            let indicator = showActivityIndicator(onView: cell.imageView, withColor: .black, isLarge: true)
            activityIndicators.append(indicator)
            print("Added spinner to ImageView")
        } else {
            let image = images[indexPath.row]
            cell.imageView.image = image
            cell.imageView.alpha = 1
            print("Added image to ImageView")
        }
        return cell
    }
}

extension PhotoAlbumViewController {
    fileprivate func showActivityIndicator(onView view: UIView, withColor color: UIColor = UIColor.black, isLarge: Bool = true) -> UIActivityIndicatorView {
        let halfx = view.bounds.width / 2
        let halfy = view.bounds.height / 2
        let lesserLength = min(halfx, halfy)
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: lesserLength, height: lesserLength))
        activityIndicator.activityIndicatorViewStyle = isLarge ? .whiteLarge : .white
        activityIndicator.color = color
        executeOnMain {
            view.alpha = 0.3
            view.addSubview(activityIndicator)
            view.bringSubview(toFront: activityIndicator)
            activityIndicator.center = CGPoint(x: halfx, y: halfy)
            activityIndicator.startAnimating()
        }
        return activityIndicator
    }
    
    fileprivate func removeAllActivityIndicators() {
        for actInd in activityIndicators {
            actInd.removeFromSuperview()
        }
        activityIndicators.removeAll(keepingCapacity: false)
    }
}
