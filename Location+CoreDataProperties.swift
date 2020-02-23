//
//  Location+CoreDataProperties.swift
//  MyLocations
//
//  Created by Nikita Kalyuzhniy on 2/23/20.
//  Copyright © 2020 Nikita Kalyuzhniy. All rights reserved.
//
//

import Foundation
import CoreData


extension Location {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Location> {
        return NSFetchRequest<Location>(entityName: "Location")
    }

    @NSManaged public var latitude: Double
    @NSManaged public var category: String?
    @NSManaged public var date: Date?
    @NSManaged public var locationDescription: String?
    @NSManaged public var longtitude: Double
    @NSManaged public var placemark: NSObject?

}
