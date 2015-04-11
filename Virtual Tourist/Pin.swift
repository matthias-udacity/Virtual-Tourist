//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Matthias on 07/04/15.
//

import Foundation
import MapKit
import CoreData

@objc(Pin)

class Pin: NSManagedObject, MKAnnotation {

    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var photos: [Photo]

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    convenience init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
        let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!

        self.init(entity: entity,insertIntoManagedObjectContext: context)

        latitude = dictionary["latitude"] as Double
        longitude = dictionary["longitude"] as Double
    }

    func setCoordinate(newCoordinate: CLLocationCoordinate2D) {
        latitude = newCoordinate.latitude
        longitude = newCoordinate.longitude
    }
}