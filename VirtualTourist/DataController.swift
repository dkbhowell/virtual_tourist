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
}
