//
//  DataController.swift
//  VirtualTourist
//
//  Created by Dustin Howell on 6/14/17.
//  Copyright © 2017 Dustin Howell. All rights reserved.
//

import UIKit
import CoreData

class DataController: NSObject {

    private let persistentContainer: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    init(completionClosure: @escaping () -> () ) {
        persistentContainer = NSPersistentContainer(name: "Model")
        persistentContainer.loadPersistentStores { (storeDesc, error) in
            if let error = error {
                print("Error loading store: \(error)")
            } else {
                print("Success loading store: \(storeDesc)")
            }
            completionClosure()
        }
    }
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving core data context: \(error)")
            }
        }
    }
    
    func deleteAllPins() {
        let context = persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<Pin>(entityName: Entity.Pin)
        do {
            let fetchedPins = try context.fetch(fetchRequest)
            for pin in fetchedPins {
                context.delete(pin)
            }
            saveContext()
        } catch {
            fatalError("Core Data: Fetch Request to delete all pins failed")
        }
    }
}


extension DataController {
    struct Entity {
        static let Pin = "Pin"
        static let Photo = "Photo"
    }
}
