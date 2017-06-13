//
//  MapPin.swift
//  VirtualTourist
//
//  Created by Dustin Howell on 6/12/17.
//  Copyright © 2017 Dustin Howell. All rights reserved.
//

import Foundation
import MapKit

class MapPin: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    init(coordinate: CLLocationCoordinate2D, title: String? = nil, subtitle: String? = nil) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
}
