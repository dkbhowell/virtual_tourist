//
//  LocationsMapViewController.swift
//  VirtualTourist
//
//  Created by Dustin Howell on 6/12/17.
//  Copyright © 2017 Dustin Howell. All rights reserved.
//

import UIKit
import MapKit

class LocationsMapViewController: UIViewController, MKMapViewDelegate {
    
    // MARK: Constants
    private let zoomConstant = 1000
    private let centerOfUnitedStates = CLLocationCoordinate2D(latitude: 39.827830, longitude: -98.578911)
    private let wholeWorldSpan = MKCoordinateSpan(latitudeDelta: 180, longitudeDelta: 360)
    private let kmPerLatitudeDegree = 111.325
    
    // MARK: Properties
    let userDefaults = UserDefaultsController.shared
    
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        if let lastRegion = userDefaults.loadRegion() {
            mapView.setRegion(lastRegion, animated: false)
        } else {
            let wholeWorldRegion = MKCoordinateRegion(center: centerOfUnitedStates, span: wholeWorldSpan)
            mapView.setRegion(wholeWorldRegion, animated: false)
        }
    }
    
    // MARK: Helper Functions
    
    private func positionMap(lat: Double, lng: Double, zoomLevel: Int = 15, animated: Bool = false) {
        let location = 	CLLocationCoordinate2D(latitude: lat, longitude: lng)
        let region = MKCoordinateRegionMakeWithDistance(location, CLLocationDistance(zoomConstant * zoomLevel), CLLocationDistance(zoomConstant * zoomLevel))
        mapView.setRegion(region, animated: animated)
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        userDefaults.save(region: mapView.region)
    }
    
    
}

