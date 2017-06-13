//
//  UserDefaultsController.swift
//  VirtualTourist
//
//  Created by Dustin Howell on 6/12/17.
//  Copyright © 2017 Dustin Howell. All rights reserved.
//

import Foundation
import MapKit

class UserDefaultsController {
    static let shared = UserDefaultsController()
    private init() {}
    
    let defaults = UserDefaults.standard
    
    func isFirstLaunchEver() -> Bool {
        guard (defaults.value(forKey: Keys.hasLaunchedBefore) as? Bool) != nil else {
            defaults.set(true, forKey: Keys.hasLaunchedBefore)
            return true
        }
        return false
    }
    
    func save(region: MKCoordinateRegion) {
        print("Saved region")
        defaults.set(region.center.latitude, forKey: Keys.lastMapLatitude)
        defaults.set(region.center.longitude, forKey: Keys.lastMapLongitude)
        defaults.set(region.span.latitudeDelta, forKey: Keys.lastMapLatDegrees)
        defaults.set(region.span.longitudeDelta, forKey: Keys.lastMapLngDegrees)
    }
    
    func loadRegion() -> MKCoordinateRegion? {
        guard let lat = defaults.value(forKey: Keys.lastMapLatitude) as? Double,
        let lng = defaults.value(forKey: Keys.lastMapLongitude) as? Double,
        let latDelt = defaults.value(forKey: Keys.lastMapLatDegrees) as? Double,
            let lngDelt = defaults.value(forKey: Keys.lastMapLngDegrees) as? Double else {
                return nil
        }
        print("Loaded region")
        return MKCoordinateRegion(center: CLLocationCoordinate2DMake(lat, lng), span: MKCoordinateSpan(latitudeDelta: latDelt, longitudeDelta: lngDelt))
    }
    
}

extension UserDefaultsController {
    struct Keys {
        static let hasLaunchedBefore = "hasLaunchedBefore"
        static let lastMapLatitude = "lastMapLatitude"
        static let lastMapLongitude = "lastMapLongitude"
        static let lastMapZoomLevel = "lastMapZoomLevel"
        static let lastMapLatDegrees = "lastMapLatDegrees"
        static let lastMapLngDegrees = "lastMapLngDegrees"
    }
}
