//
//  ImageGroup+CoreDataClass.swift
//  past-nyc
//
//  Created by Aramis on 11/25/21.
//
//

import CoreData
import MapKit


public class ImageGroup: NSManagedObject {
    convenience init(from jsonObject: DataLoader.JSONHistoricalImageGroup, withContext context: NSManagedObjectContext){
        self.init(context: context)
        self.latitude = jsonObject.latitude
        self.longitude = jsonObject.longitude
        
        jsonObject.photos.forEach { jsonPhoto in
            let image = HistoricalImage(from: jsonPhoto, withParent: self, withContext: context)
            self.addToImageSet(image)
        }
    }
    
    var images: [HistoricalImage] {
        willAccessValue(forKey: "images")
        defer {didAccessValue(forKey: "images")}
        guard let imageSet = imageSet as? Set<HistoricalImage>
        else {
            print("Failed to cast NSSet")
            return []
        }
        
        // The ordering here is pretty arbitrary, just needed an array
        // On an off note: i think consecutive (id-wise) images potentially
        // share a textual description.
        return imageSet.sorted {
            ($0.nyplID ?? "") < ($1.nyplID ?? "")
        }
    }
    
    var sampleImage: HistoricalImage? {
        willAccessValue(forKey: "images")
        defer {didAccessValue(forKey: "images")}
        guard let imageSet = imageSet as? Set<HistoricalImage>
        else {
            print("Failed to cast NSSet")
            return nil
        }
        return imageSet.randomElement()
    }
    
    var imageCount: Int {
        imageSet?.count ?? 0
    }

}

extension ImageGroup: MKAnnotation {
    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2DMake(Double(latitude), Double(longitude))
    }
    public var title: String? {
        nil
    }
    public var subtitle: String? {
        nil
    }
}
