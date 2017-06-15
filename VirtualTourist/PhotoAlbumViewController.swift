//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Dustin Howell on 6/13/17.
//  Copyright © 2017 Dustin Howell. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, ImageDownloaderDelegate {
    
    // MARK: Constants
    private let maxPhotos = 100
    
    // MARK: Properties
    var pin: Pin!
    let imageDownloader = ImageDownloader()
    let dataController = (UIApplication.shared.delegate as! AppDelegate).dataController
    
    var urlsAndImages: [Any] {
        let imageCount = images.count
        let urlsAsAny = imageUrls as [Any]
        let imagesAsAny = images as [Any]
        let imageURLsShortened = urlsAsAny.dropFirst(imageCount)
        return imagesAsAny + imageURLsShortened
    }
    
    var imageUrls = [URL]() {
        didSet {
//            print("Reloading collection view from imageUrl didSet")
            executeOnMain {
                self.collectionView.reloadData()
            }
        }
    }
    var images = [UIImage]() {
        didSet {
            imagesAvailable = true
            executeOnMain {
//                print("Reloading collection view from images didSet")
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
        imageDownloader.delegate = self
        
        print("Selecting pin")
        mapView.addAnnotation(pin)
        mapView.showAnnotations([pin], animated: true)
        
        print("Checking DB for Images")
        if doImagesExistInDb() {
            getDownloadedImages()
        } else {
            getImagesFromFlickr()
        }
        
//        if !hasData {
//            print("DB Miss -- Downlaoding images from Flickr...")
//            getImagesFromFlickr()
//        }
    }
    
    // MARK: ImageDownloaderDelegate
    func downloader(_ downloader: ImageDownloader, didDownloadImage image: UIImage) {
        print("Image Downloaded")
        images.append(image)
        // associate with pin
        let data = UIImagePNGRepresentation(image)!
        let imageObject = NSEntityDescription.insertNewObject(forEntityName: "Photo", into: dataController.viewContext) as! Photo
        imageObject.image = data as NSData
        imageObject.pin = pin
        dataController.saveContext()
    }
    
    // MARK: Helper Methods
    
    private func getImagesFromFlickr() {
        let flickrClient = FlickrClient.shared
        flickrClient.photoSearch(latitude: pin.coordinate.latitude, longitude: pin.coordinate.longitude) { (result) in
            switch result {
            case .success(let urls):
                print("Successfully retreived \(urls.count) image URLs")
                self.imageUrls = urls
                self.imageDownloader.downloadImages(urls: urls)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func doImagesExistInDb() -> Bool {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin = %@", argumentArray: [pin])
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1
        let timeStart = Date()
        do {
            let fetchedResult = try dataController.viewContext.fetch(fetchRequest)
            let timeEnd = Date()
            print("Time Elapsed for Quick DB: \(timeEnd.timeIntervalSince(timeStart))")
            if fetchedResult.count > 0 {
                return true
            }
            
        } catch {
            fatalError("Core Data: Error fetching a photo from the database")
        }
        return false
    }
    
    private func getDownloadedImages() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin = %@", argumentArray: [pin])
        fetchRequest.predicate = predicate
        let timeStart = Date()
        let asyncFetch = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { (fetchResult) in
            executeOnMain {
                guard let photos = fetchResult.finalResult, photos.count > 0 else {
                    print("Async Fetch: No results")
                    return
                }
                let timeAfterDB = Date()
                self.processDbImages(photos: photos)
                let timeAfterProcess = Date()
                print("Time for DB Access: \(timeAfterDB.timeIntervalSince(timeStart))")
                print("Time for Image Processing: \(timeAfterProcess.timeIntervalSince(timeAfterDB))")
            }
        }
        do {
            let fetchedPhotosResult = try dataController.viewContext.execute(asyncFetch)
            print("FetchedPhotosResult Immediately After: \(fetchedPhotosResult)")
        } catch {
            fatalError("Core Data: Error fetching a photo from the database")
        }
    }
    
    private func processDbImages(photos: [Photo]) {
        print("DB Hit -- loading Images from DB")
        var count = 0
        for photo in photos {
            let data = photo.image! as Data
            let image = UIImage(data: data)!
            self.images.append(image)
            count += 1
        }
        print("Loaded \(count) images from the DB")
    }
}


extension PhotoAlbumViewController: UICollectionViewDataSource {
    var cellReuseIdentefier: String { return "photoCell" }
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = urlsAndImages.count
//        let count = imagesAvailable ? images.count : imageUrls.count
        print("numberOfItemsInSection: \(count)")
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentefier, for: indexPath) as! ImageCollectionViewCell
        cell.backgroundColor = UIColor.lightGray
        
        let imageOrUrl = urlsAndImages[indexPath.row]
        switch imageOrUrl {
        case let image as UIImage:
            cell.configureWithImage(image: image)
        default:
            cell.configureWithImage(image: nil)
        }
        return cell
    }
}
