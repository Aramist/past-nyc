//
//  HistoricalImage+CoreDataProperties.swift
//  past-nyc
//
//  Created by Aramis on 11/25/21.
//
//

import Foundation
import CoreData


extension HistoricalImage {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HistoricalImage> {
        return NSFetchRequest<HistoricalImage>(entityName: "HistoricalImage")
    }

    @NSManaged public var thumbnailURL: String?
    @NSManaged public var fullsizeURL: String?
    @NSManaged public var nyplID: String?
    @NSManaged public var photoDescription: String?
    @NSManaged public var intersection: String?
    @NSManaged public var imageWidth: Int32
    @NSManaged public var imageHeight: Int32
    @NSManaged public var date: String?
    @NSManaged public var parentGroup: ImageGroup?

}

extension HistoricalImage : Identifiable {

}
