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

class PhotoAlbumViewController: UIViewController, ImageDownloaderDelegate, ImageCreatorDelegate, UICollectionViewDelegate {
    // MARK: Constants
    private let maxPhotos = 100
    
    // MARK: Properties
    var pin: Pin!
    let imageDownloader = ImageDownloader()
    let imageCreator = ImageCreator()
    let dataController = (UIApplication.shared.delegate as! AppDelegate).dataController
    
    var images = [UIImage?]() {
        didSet {
            executeOnMain {
                //                print("Reloading collection view from images didSet")
                self.collectionView.reloadData()
            }
        }
    }
    
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var titleLabel: UILabel!
    
    // MARK: VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = false
        collectionView.dataSource = self
        imageDownloader.delegate = self
        imageCreator.delegate = self
        
        titleLabel.text = pin.title
        
        mapView.addAnnotation(pin)
        mapView.showAnnotations([pin], animated: true)
        
        print("Checking DB for Images")
        if doImagesExistInDb() {
            print("Images Exist in DB")
            getDownloadedImages()
        } else {
            print("No images in DB -- fetching from Flickr")
            getImagesFromFlickr()
        }
//        configCollectionView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
//        configCollectionView()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        configCollectionView()
        toggleMapView()
    }
    
    private func toggleMapView() {
        let isPortrait = UIApplication.shared.statusBarOrientation == .portrait
        mapView.isHidden = isPortrait ? false : true
        self.navigationController?.navigationBar.isHidden = isPortrait ? false : true
    }
    
    // MARK: Actions
    @IBAction func newCollectionTapped(_ sender: Any) {
        print("Fetching new collection of photos for pin...")
        // Remove all photos from UI
        images.removeAll()
        // Delete all photos from DB
        deleteAllPhotos()
        // Fetch new photos
        getImagesFromFlickr()
    }
    
    // MARK: ImageDownloaderDelegate
    func downloader(_ downloader: ImageDownloader, didDownloadImage image: UIImage) {
        print("Image Downloaded")
        insertValue(element: image, array: &images)
        
        // associate with pin
        let data = UIImagePNGRepresentation(image)!
        let imageObject = NSEntityDescription.insertNewObject(forEntityName: "Photo", into: dataController.viewContext) as! Photo
        imageObject.image = data as NSData
        imageObject.pin = pin
        dataController.saveContext()
    }
    
    // MARK: ImageCreatorDelegate (from DB)
    func creator(_ creator: ImageCreator, didCreateImage image: UIImage) {
        images.append(image)
    }
    
    // MARK: UICollectionViewDelegate 
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let photo = images[safe: indexPath.row] as? Photo else {
            print("Selected photo does not exist in array")
            return
        }
    }
    
    // MARK: Helper Methods
    
    private func insertValue<T>(element: T, array: inout [T?]) {
        if let nilIndex = array.index(where: { $0 == nil} ) {
            array[nilIndex] = element
        } else {
            array.append(element)
        }
    }
    
    private func configCollectionView() {
        guard let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }
        let orientation = UIApplication.shared.statusBarOrientation
        let numItemsPerRow: CGFloat = orientation == .portrait ? 2 : 3
        let itemSpacing: CGFloat = 5
        let lineSpacing: CGFloat = 5
        let width = collectionView.frame.width
        let computedWidth = width - (numItemsPerRow - 1) * itemSpacing
        flowLayout.itemSize = CGSize(width: computedWidth/numItemsPerRow, height: computedWidth/numItemsPerRow)
        flowLayout.minimumInteritemSpacing = itemSpacing
        flowLayout.minimumLineSpacing = lineSpacing
        flowLayout.invalidateLayout()
    }
    
    private func getImagesFromFlickr() {
        let flickrClient = FlickrClient.shared
        flickrClient.photoSearch(latitude: pin.coordinate.latitude, longitude: pin.coordinate.longitude) { (result) in
            switch result {
            case .success(let urls):
                print("Successfully retreived \(urls.count) image URLs")
                self.images = [UIImage?](repeating: nil, count: urls.count)
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
    
    private func getImagesInDatabase() -> [Photo] {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin = %@", argumentArray: [pin])
        fetchRequest.predicate = predicate
        do {
            return try dataController.viewContext.fetch(fetchRequest)
        } catch {
            fatalError("Core Data: Error fetching photo from the database")
        }
    }
    
    private func deleteAllPhotos() {
        let photos = getImagesInDatabase()
        for photo in photos {
            dataController.viewContext.delete(photo)
        }
        dataController.saveContext()
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
                print("Time for DB Access: \(timeAfterDB.timeIntervalSince(timeStart))")
//                self.processPhotosNoUI(photos: photos)
                self.processDbImages(photos: photos)
            }
        }
        do {
            let fetchedPhotosResult = try dataController.viewContext.execute(asyncFetch)
            print("FetchedPhotosResult Immediately After: \(fetchedPhotosResult)")
        } catch {
            fatalError("Core Data: Error fetching a photo from the database")
        }
    }
    
    private func processPhotosNoUI(photos: [Photo]) {
        print("Starting Image Processing (no UI)")
        let startTime = Date()
        var count = 0
        for photo in photos {
            let data = photo.image! as Data
            if data.count > 800000 {
                print("Large image in DB: \(sizeInKB(data: data))")
            }
            let _ = UIImage(data: data)!
            count += 1
        }
        let endTime = Date()
        print("End Processing (no UI) \n--elapsed time: \(endTime.timeIntervalSince(startTime))\n--Photos: \(count)")
    }
    
    private func processDbImages(photos: [Photo]) {
        print("Starting Image Processing")
        let startTime = Date()
        var count = 0
        var dataRay = [Data]()
        for photo in photos {
            let data = photo.image! as Data
            if data.count > 800000 {
                print("Image size in DB: \(sizeInKB(data: data))")
            }
            dataRay.append(data)
            count += 1
        }
        imageCreator.createImages(data: dataRay)
        let endTime = Date()
        print("End Processing \n--elapsed time: \(endTime.timeIntervalSince(startTime))\n--Photos: \(count)")
    }
    
    private func sizeInKB(data: Data) -> String {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useKB]
        bcf.countStyle = .file
        
        return bcf.string(fromByteCount: Int64(data.count))
    }
}


extension PhotoAlbumViewController: UICollectionViewDataSource {
    var cellReuseIdentefier: String { return "photoCell" }
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = images.count
//        let count = imagesAvailable ? images.count : imageUrls.count
        print("numberOfItemsInSection: \(count)")
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentefier, for: indexPath) as! ImageCollectionViewCell
        cell.backgroundColor = UIColor.lightGray
        
        if let image = images[safe: indexPath.row] {
            cell.configureWithImage(image: image)
        } else {
            cell.configureWithImage(image: nil)
        }
        return cell
    }
}
