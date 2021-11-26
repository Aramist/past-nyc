//
//  ImageGroup+CoreDataProperties.swift
//  past-nyc
//
//  Created by Aramis on 11/25/21.
//
//

import Foundation
import CoreData


extension ImageGroup {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ImageGroup> {
        return NSFetchRequest<ImageGroup>(entityName: "ImageGroup")
    }

    @NSManaged public var latitude: Float
    @NSManaged public var longitude: Float
    @NSManaged public var imageSet: NSSet?

}

// MARK: Generated accessors for imageSet
extension ImageGroup {

    @objc(addImageSetObject:)
    @NSManaged public func addToImageSet(_ value: HistoricalImage)

    @objc(removeImageSetObject:)
    @NSManaged public func removeFromImageSet(_ value: HistoricalImage)

    @objc(addImageSet:)
    @NSManaged public func addToImageSet(_ values: NSSet)

    @objc(removeImageSet:)
    @NSManaged public func removeFromImageSet(_ values: NSSet)

}

extension ImageGroup : Identifiable {

}
