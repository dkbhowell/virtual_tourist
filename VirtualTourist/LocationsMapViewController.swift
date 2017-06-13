//
//  LocationsMapViewController.swift
//  VirtualTourist
//
//  Created by Dustin Howell on 6/12/17.
//  Copyright © 2017 Dustin Howell. All rights reserved.
//

import UIKit
import MapKit

class LocationsMapViewController: UIViewController {
    
    // MARK: Constants
    private let zoomConstant = 1000
    private let centerOfUnitedStates = CLLocationCoordinate2D(latitude: 39.827830, longitude: -98.578911)
    private let wholeWorldSpan = MKCoordinateSpan(latitudeDelta: 180, longitudeDelta: 360)
    private let kmPerLatitudeDegree = 111.325
    
    // MARK: Properties
    fileprivate let userDefaults = UserDefaultsController.shared
    
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureMapView()
    }
    
    // MARK: Helper Functions
    
    private func configureMapView() {
        mapView.delegate = self
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)) )
        longPressRecognizer.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressRecognizer)
        loadMapRegion()
    }
    
    @objc private func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state != .began { return }
        let touchPoint = gestureRecognizer.location(in: mapView)
        let touchPointCoord = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let mapPin = MapPin(coordinate: touchPointCoord, title: "New Pin")
        mapView.addAnnotation(mapPin)
        mapView.selectAnnotation(mapPin, animated: true)
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
        guard let annotation = annotation as? MapPin else {
            return nil
        }
        let identifier = "simplePin"
        var pinView: MKPinAnnotationView
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView {
            dequeuedView.annotation = annotation
            (dequeuedView.leftCalloutAccessoryView as? ClosureButton)?.touchUpAction = { [weak annotation, weak mapView] in
                if let annotation = annotation, let mapView = mapView {
                    mapView.removeAnnotation(annotation)
                }
            }
            pinView = dequeuedView
        } else {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            pinView.canShowCallout = true
            pinView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            let deleteButton = ClosureButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
            deleteButton.backgroundColor = UIColor.red
            deleteButton.setTitle("X", for: .normal)
            deleteButton.touchUpAction = { [weak annotation, weak mapView] in
                if let annotation = annotation, let mapView = mapView {
                    mapView.removeAnnotation(annotation)
                }
            }
            pinView.leftCalloutAccessoryView = deleteButton
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        print("Annotation Control Tapped:\n--Annotation: \(view.annotation?.title)\n--Control: \(control)")
    }
}

