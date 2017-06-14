//
//  Pin+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Dustin Howell on 6/14/17.
//  Copyright © 2017 Dustin Howell. All rights reserved.
//

import Foundation
import CoreData
import MapKit

@objc(Pin)
public class Pin: NSManagedObject, MKAnnotation {

    public var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
        }
        set {
            self.latitude = newValue.latitude
            self.longitude = newValue.longitude
        }
    }
    
    convenience init(coordinate: CLLocationCoordinate2D, title: String? = nil, subtitle: String? = nil, context: NSManagedObjectContext) {
        guard let entity = NSEntityDescription.entity(forEntityName: "Pin", in: context) else {
            fatalError("Pin Entity not found in data model")
        }
        self.init(entity: entity, insertInto: context)
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
    
}
