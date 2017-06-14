//
//  Pin+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Dustin Howell on 6/14/17.
//  Copyright © 2017 Dustin Howell. All rights reserved.
//

import Foundation
import CoreData


extension Pin {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Pin> {
        return NSFetchRequest<Pin>(entityName: "Pin")
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var subtitle: String?
    @NSManaged public var title: String?

}
