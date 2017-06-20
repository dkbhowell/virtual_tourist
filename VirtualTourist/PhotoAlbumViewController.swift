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

class PhotoAlbumViewController: UIViewController, ImageDownloaderDelegate, UICollectionViewDelegate {
    // MARK: Constants
    private let maxPhotos = 80
    
    // MARK: Properties
    var pin: Pin!
    let imageDownloader = ImageDownloader()
    let dataController = (UIApplication.shared.delegate as! AppDelegate).dataController
    
    var photos = [Photo?]()
    
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    // MARK: VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = false
        collectionView.dataSource = self
        collectionView.delegate = self
        imageDownloader.delegate = self
        
        self.newCollectionButton.isEnabled = false
        
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        } else {
            print("3D Touch Not Available")
        }
        
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
        photos.removeAll()
        collectionView.reloadData()
        deleteAllPhotos()
        getImagesFromFlickr()
    }
    
    // MARK: ImageDownloaderDelegate
    func downloader(_ downloader: ImageDownloader, didDownloadImage image: UIImage) {
        print("Image Downloaded")
        let photo = saveImageToDb(image: image)
        insertValue(image: photo)
    }
    
    func downloader(_ downloader: ImageDownloader, didFinishDownloadingImages: Bool) {
        if didFinishDownloadingImages {
            self.newCollectionButton.isEnabled = true
        }
    }
    
    // MARK: UICollectionViewDelegate 
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let photo = photos[safe: indexPath.row] as? Photo else {
            print("Selected photo does not exist in array")
            return
        }
        print("Photo Selected at index: \(indexPath.row)")
        photos.remove(at: indexPath.row)
        collectionView.deleteItems(at: [indexPath])
        deleteFromDb(photo: photo)
    }
    
    // MARK: Helper Methods
    
    private func saveImageToDb(image: UIImage) -> Photo {
        let data = UIImagePNGRepresentation(image)!
        let photoObject = NSEntityDescription.insertNewObject(forEntityName: "Photo", into: dataController.viewContext) as! Photo
        photoObject.image = data as NSData
        photoObject.pin = pin
        dataController.saveContext()
        return photoObject
    }
    
    private func deleteFromDb(photo: Photo) {
        dataController.viewContext.delete(photo)
        dataController.saveContext()
    }
    
    private func insertValue(image: Photo) {
        if let nilIndex = photos.index(where: { $0 == nil} ) {
            photos[nilIndex] = image
            collectionView.reloadItems(at: [IndexPath(row: nilIndex, section: 0)])
        } else {
            photos.append(image)
            collectionView.insertItems(at: [IndexPath(row: (photos.endIndex - 1), section: 0)])
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
                let newUrlArray = Array(urls.prefix(self.maxPhotos))
                self.photos = [Photo?](repeating: nil, count: newUrlArray.count)
                self.collectionView.reloadData()
                self.imageDownloader.downloadImages(urls: newUrlArray)
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
            guard let photos = fetchResult.finalResult, photos.count > 0 else {
                print("Async Fetch: No results")
                return
            }
            let timeAfterDB = Date()
            print("Time for DB Access: \(timeAfterDB.timeIntervalSince(timeStart))")
            self.photos = photos
            self.collectionView.reloadData()
            self.newCollectionButton.isEnabled = true
        }
        do {
            let fetchedPhotosResult = try dataController.viewContext.execute(asyncFetch)
            print("FetchedPhotosResult Immediately After: \(fetchedPhotosResult)")
        } catch {
            fatalError("Core Data: Error fetching a photo from the database")
        }
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
        let count = photos.count
        print("numberOfItemsInSection: \(count)")
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("cellForItemAt: \(indexPath.row)")
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentefier, for: indexPath) as! ImageCollectionViewCell
        cell.backgroundColor = UIColor.lightGray
        if let photoOpt = photos[safe: indexPath.row], let imageData = photoOpt?.image as Data? {
            let image = UIImage(data: imageData)
            cell.configureWithImage(image: image)
        } else {
            cell.configureWithImage(image: nil)
        }
        return cell
    }
}

extension PhotoAlbumViewController:  UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        let newPoint = self.view.convert(location, to: collectionView)
        
        guard let indexPath = collectionView.indexPathForItem(at: newPoint), let cell = collectionView.cellForItem(at: indexPath) else {
            print("No Index Path for preview")
            return nil
        }
        
        guard let photoVC = storyboard?.instantiateViewController(withIdentifier: "PhotoViewController") as? PhotoViewController else {
            print("No controller for preview")
            return nil
        }
        
        print("Force Touch recognized for row: \(indexPath.row)")
        
        photoVC.photo = photos[indexPath.row]
        photoVC.preferredContentSize = CGSize(width: 0, height: 600)
        previewingContext.sourceRect = cell.frame
        return photoVC
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        self.navigationController?.pushViewController(viewControllerToCommit, animated: true)
    }
    
}















