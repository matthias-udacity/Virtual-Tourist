//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Matthias on 07/04/15.
//

import UIKit
import CoreData

@objc(Photo)

class Photo: NSManagedObject {

    @NSManaged var id: String
    @NSManaged var imageURL: String
    @NSManaged var pin: Pin?

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    convenience init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!

        self.init(entity: entity,insertIntoManagedObjectContext: context)

        id = dictionary["id"] as String
        imageURL = dictionary["imageURL"] as String
    }
}