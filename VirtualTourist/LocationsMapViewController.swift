//
//  LocationsMapViewController.swift
//  VirtualTourist
//
//  Created by Dustin Howell on 6/12/17.
//  Copyright © 2017 Dustin Howell. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class LocationsMapViewController: UIViewController {
    
    // MARK: Constants
    private let zoomConstant = 1000
    private let centerOfUnitedStates = CLLocationCoordinate2D(latitude: 39.827830, longitude: -98.578911)
    private let wholeWorldSpan = MKCoordinateSpan(latitudeDelta: 180, longitudeDelta: 360)
    private let kmPerLatitudeDegree = 111.325
    
    // MARK: Properties
    fileprivate let userDefaults = UserDefaultsController.shared
    fileprivate let dataController = (UIApplication.shared.delegate as! AppDelegate).dataController
    
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var trashButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureMapView()
    }
    
    @IBAction func trashButtonTapped(_ sender: UIBarButtonItem) {
        guard let pins = mapView.annotations as? [Pin] else {
            print("Could not get annotations from map as Pin instances")
            return
        }
        if pins.count > 0 {
            let alert = UIAlertController(title: "Delete All Pins?", message: "This will delete all pins, and all images associated with those pins. Continue?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (action) in
                print("Deleting all pins")
                self.dataController.deleteAllPins()
                self.mapView.removeAnnotations(self.mapView.annotations)
            }))
            alert.addAction(UIAlertAction(title: "Nope", style: .default, handler: { (action) in
                print("Do not delete all pins")
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "No Pins To Delete", message: "You cannot delete pins, because you don't have any! Long press on the screen to drop a pin.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func seeAllPinsTapped(_ sender: UIBarButtonItem) {
        if mapView.annotations.count > 0 {
            mapView.showAnnotations(mapView.annotations, animated: true)
        } else {
            let wholeWorldRegion = MKCoordinateRegion(center: centerOfUnitedStates, span: wholeWorldSpan)
            mapView.setRegion(wholeWorldRegion, animated: true)
        }
        
    }
    
    // MARK: Helper Functions
    
    private func configureMapView() {
        mapView.delegate = self
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)) )
        longPressRecognizer.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressRecognizer)
        loadMapRegion()
        loadPins()
    }
    
    @objc private func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state != .began { return }
        let touchPoint = gestureRecognizer.location(in: mapView)
        let touchPointCoord = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let mapPin = Pin(coordinate: touchPointCoord, title: "New Location", subtitle: "Tap for Pics!", context: dataController.viewContext)
        dataController.saveContext()
        mapView.addAnnotation(mapPin)
        mapView.selectAnnotation(mapPin, animated: true)
        
        let location = CLLocation(latitude: touchPointCoord.latitude, longitude: touchPointCoord.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { (placemark, error) in
            if let error = error {
                print("Error with reverse geocode: \(error)")
            }
            if let placemark = placemark?.first {
                print("Successful reverse geocode: \(placemark)")
                if let placeTitle = placemark.locality {
                    mapPin.title = placeTitle
                }else {
                    mapPin.title = "Unknown Place"
                }
                self.dataController.saveContext()
            }
        }
    }
    
    private func loadPins() {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        do {
            let fetchedPins = try dataController.viewContext.fetch(fetchRequest)
            for pin in fetchedPins {
                mapView.addAnnotation(pin)
            }
            mapView.showAnnotations(fetchedPins, animated: true)
        } catch {
            fatalError("Failed fetch request for Pin entity")
        }
    }
    
    private func loadMapRegion() {
        if let lastRegion = userDefaults.loadRegion() {
            mapView.setRegion(lastRegion, animated: false)
        } else {
            let wholeWorldRegion = MKCoordinateRegion(center: centerOfUnitedStates, span: wholeWorldSpan)
            mapView.setRegion(wholeWorldRegion, animated: false)
        }
    }
    
    private func positionMap(lat: Double, lng: Double, zoomLevel: Int = 15, animated: Bool = false) {
        let location = 	CLLocationCoordinate2D(latitude: lat, longitude: lng)
        let region = MKCoordinateRegionMakeWithDistance(location, CLLocationDistance(zoomConstant * zoomLevel), CLLocationDistance(zoomConstant * zoomLevel))
        mapView.setRegion(region, animated: animated)
    }
}


extension LocationsMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        userDefaults.save(region: mapView.region)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? Pin else {
            return nil
        }
        let identifier = "simplePin"
        var pinView: MKPinAnnotationView
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView {
            dequeuedView.annotation = annotation
            (dequeuedView.leftCalloutAccessoryView as? ClosureButton)?.touchUpAction = { [weak annotation, weak mapView] in
                if let annotation = annotation, let mapView = mapView {
                    mapView.removeAnnotation(annotation)
                    self.dataController.viewContext.delete(annotation)
                    self.dataController.saveContext()
                }
            }
            pinView = dequeuedView
        } else {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            pinView.canShowCallout = true
            pinView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            let deleteButton = ClosureButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            deleteButton.layer.cornerRadius = 10
            deleteButton.clipsToBounds = true
            deleteButton.backgroundColor = UIColor.red
            deleteButton.setTitle("X", for: .normal)
            deleteButton.touchUpAction = { [weak annotation, weak mapView] in
                if let annotation = annotation, let mapView = mapView {
                    mapView.removeAnnotation(annotation)
                    self.dataController.viewContext.delete(annotation)
                    self.dataController.saveContext()
                }
            }
            pinView.leftCalloutAccessoryView = deleteButton
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if (control as? UIButton)?.buttonType == .detailDisclosure {
            let controller = (self.storyboard?.instantiateViewController(withIdentifier: "PhotoAlbumViewController")) as! PhotoAlbumViewController
            let pin = (view.annotation as? Pin)
            controller.pin = pin
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
}

