//
//  HistoricalImage+CoreDataClass.swift
//  past-nyc
//
//  Created by Aramis on 11/25/21.
//
//

import CoreData
import UIKit


public class HistoricalImage: NSManagedObject {

    //TODO: Implement a static watchdog for the number of cached images to prevent it from going
    //TODO: above a certain amount. Implement a fileprivate function to decache images not recently
    //TODO: accessed
    var thumbnailImage: UIImage?
    var fullImage: UIImage?
    
    convenience init(from jsonObject: DataLoader.JSONHistoricalImage, withParent parent: ImageGroup, withContext context: NSManagedObjectContext) {
        self.init(context: context)
        date = jsonObject.date
        photoDescription = jsonObject.text
        nyplID = jsonObject.id
        fullsizeURL = jsonObject.image_url
        thumbnailURL = jsonObject.thumb_url
        intersection = jsonObject.folder
        imageWidth = Int32(jsonObject.width)
        imageHeight = Int32(jsonObject.height)
        parentGroup = parent
    }
    
    func copyWithoutContext(withParent parent: ImageGroup) -> HistoricalImage {
        let clone = NSManagedObject(entity: entity, insertInto: nil) as! HistoricalImage
        clone.thumbnailURL = thumbnailURL
        clone.fullsizeURL = fullsizeURL
        clone.intersection = intersection
        clone.nyplID = nyplID
        clone.photoDescription = nil
        clone.imageWidth = imageWidth
        clone.imageHeight = imageHeight
        clone.parentGroup = parent
        return clone
    }
    
    var isWide: Bool {
        imageWidth > imageHeight
    }
    
    var aspectRatio: CGFloat {
        CGFloat(imageWidth) / CGFloat(imageHeight)
    }
    
    func cacheThumbnailImage(completion: ((_ image: UIImage?, _ success: Bool) -> ())? ) {
        guard let thumbnailString = thumbnailURL,
              let thumbnailURL = URL(string: thumbnailString)
        else {
            completion?(nil, false)
            return
        }
        
        URLSession.shared.dataTask(with: thumbnailURL) { [weak self] (data, response, error) in
            if let data = data{
                guard let self = self,
                      let image = UIImage(data: data)
                else {return}
                
                self.thumbnailImage = image
                DispatchQueue.main.async {
                    completion?(image, true)
                }
            }
            DispatchQueue.main.async {
                completion?(nil, false)
            }
        }.resume()
    }
    
    func assignThumbnailImage(
        to imageView: UIImageView,
        completion: ((_ success: Bool) -> ())?
    ) {
        if let thumbnailImage = thumbnailImage {
            imageView.image = thumbnailImage
            completion?(true)
            return
        }
        
        cacheThumbnailImage { [weak imageView] image, success in
            guard success,
                  let image = image
            else {
                // Just in case it contains UI code
                DispatchQueue.main.async {
                    completion?(false)
                }
                return
            }
            
            DispatchQueue.main.async {
                guard let imageView = imageView else { return }
                imageView.image = image
                completion?(true)
            }
        }
    }
    
    func cacheFullImage(completion: ((_ image: UIImage?, _ success: Bool) -> ())? ) {
        guard let imageURLString = fullsizeURL,
              let imageURL = URL(string: imageURLString)
        else {
            completion?(nil, false)
            return
        }
        
        URLSession.shared.dataTask(with: imageURL) { [weak self] (data, response, error) in
            if let data = data{
                guard let self = self,
                      let image = UIImage(data: data)
                else {return}
                
                self.fullImage = image
                DispatchQueue.main.async {
                    completion?(image, true)
                }
            }
            DispatchQueue.main.async {
                completion?(nil, false)
            }
        }.resume()
    }
    
    func assignFullImage(
        to imageView: UIImageView,
        completion: ((_ success: Bool) -> ())?
    ) {
        if let fullImage = fullImage {
            imageView.image = fullImage
            completion?(true)
            return
        }
        
        cacheFullImage { [weak imageView] image, success in
            guard success,
                  let image = image
            else {
                // Just in case it contains UI code
                DispatchQueue.main.async {
                    completion?(false)
                }
                return
            }
            
            DispatchQueue.main.async {
                guard let imageView = imageView else { return }
                imageView.image = image
                completion?(true)
            }
        }
    }
}
