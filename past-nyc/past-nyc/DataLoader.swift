//
//  DataLoader.swift
//  past-nyc
//
//  Created by Aramis on 11/25/21.
//


import CoreData
import MapKit


class DataLoader {
    
    enum DatabaseError: Error {
        case failedToOpenFile
        case invalidJSON
        case invalidCoreDataContext
    }
    
    /// Codable structs for decoding the local json dataset
    struct JSONHistoricalImageGroup: Codable {
        var latitude: Float
        var longitude: Float
        var photos: [JSONHistoricalImage]
    }
    
    struct JSONHistoricalImage: Codable{
        var thumb_url: String  // Thumbnail, useful for map view
        var image_url: String  // Full image, useful for detail view
        var date: String?  // The year the photo was taken
        var text: String?  // A description of the image
        var folder: String?  // Seems to contain the intersection at which the photo was taken
        var id: String // The id of the image in the NYPL database
        var height: Int
        var width: Int
    }
    
    // Singleton instance
    static let main: DataLoader? = DataLoader()
    
    fileprivate let jsonDataFileName = "local_image_dataset"
    let maxLoadedImageGroups = 80
    var context: NSManagedObjectContext
    var dataSuccessfullyLoaded = false
    
    fileprivate init?() {
        guard let appDelegate = (UIApplication.shared.delegate as? AppDelegate) else {return nil}
        context = appDelegate.persistentContainer.viewContext
        
        // See if the local cache has been imported from JSON yet
        let entityCount = try? context.count(for: ImageGroup.fetchRequest())
        if (entityCount ?? 0) > 0 {
            dataSuccessfullyLoaded = true
            return
        }
        
        // Import the data from JSON
        // Use a private queue to avoid lagging the main thread
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = context
        privateContext.perform {
            do {
                try self.loadJSONDatabase(withContext: privateContext)
                do {
                    try self.context.save()
                    self.dataSuccessfullyLoaded = true
                } catch {
                    print("Failed to save parent context: \(error)")
                }
            } catch {
                print("Failed to load JSON Dataset: \(error)")
            }
        }
        
    }
    
    fileprivate func fetchImages(inRange coordinateRange: [CLLocationCoordinate2D], withContext context: NSManagedObjectContext) throws -> [ImageGroup]?{
        guard coordinateRange.count == 2
        else {
            // Might be more appropriate to throw an error here?
            return nil
        }
        guard dataSuccessfullyLoaded else {return nil}
        let minLat = min(coordinateRange[0].latitude, coordinateRange[1].latitude)
        let maxLat = max(coordinateRange[0].latitude, coordinateRange[1].latitude)
        let minLon = min(coordinateRange[0].longitude, coordinateRange[1].longitude)
        let maxLon = max(coordinateRange[0].longitude, coordinateRange[1].longitude)
        
        guard minLat < maxLat,
              minLon < maxLon
        else {
            // A degenerate box can't contain any points
            return []
        }
        
        let request = ImageGroup.fetchRequest()
        request.fetchLimit = maxLoadedImageGroups
        // Couldn't get the BETWEEN keyword to work out here
        let predicate = NSPredicate(
            format: "(%K >= %@) && (%K <= %@) && (%K >= %@) && (%K <= %@)",
            argumentArray: [
                #keyPath(ImageGroup.latitude), minLat,
                #keyPath(ImageGroup.latitude), maxLat,
                #keyPath(ImageGroup.longitude), minLon,
                #keyPath(ImageGroup.longitude), maxLon
            ]
        )
        request.predicate = predicate
        
        do {
            let nearbyImages = try context.fetch(request)
            return nearbyImages
        }
        catch {
            throw error
        }
    }
    
    /// Loads the local image database JSON file and uses it to populate
    /// the table view's data source, imageDatabase
    fileprivate func loadJSONDatabase(withContext privateContext: NSManagedObjectContext) throws {
        // TODO: learn what the inDirectory: argument actually does
        if let jsonPath = Bundle.main.path(forResource: jsonDataFileName, ofType: "json") {
            do {
                let jsonData = try String(contentsOfFile: jsonPath).data(using: .utf8)
                guard let jsonData = jsonData else {
                    throw DatabaseError.failedToOpenFile
                }
                
                let jsonImageDataset = try JSONDecoder().decode([JSONHistoricalImageGroup].self, from: jsonData)
                
                var refs: [ImageGroup] = []
                for jsonImageData in jsonImageDataset {
                    let newGroup = ImageGroup(from: jsonImageData, withContext: privateContext)
                    refs.append(newGroup)
                }
                try privateContext.save()
            }
            // TODO: Diversify error responses
            catch DecodingError.dataCorrupted(_), DecodingError.keyNotFound(_, _), DecodingError.typeMismatch(_, _), DecodingError.valueNotFound(_, _){
                throw DatabaseError.invalidJSON
            }
            catch {
                throw DatabaseError.failedToOpenFile
            }
        } else {
            throw DatabaseError.failedToOpenFile
        }
    }
}


//MARK: Extensions and Protocols
protocol ImageSource {
    /// Max number of image groups to maintain in memory
    var loadedImageLimit: Int { get }
    /// Obtain new images from a given coordinate range
    func getImages(inRegion region: MKCoordinateRegion) -> [ImageGroup]
    /// Obtain new images from a given coordinate range, but exclude pre-acquired images
    func newImages(
        inRegion region: MKCoordinateRegion,
        withPriorImages prior: [ImageGroup]
    ) -> [ImageGroup]
    func testPrivateRequest(
        inRegion region: MKCoordinateRegion,
        completion: ((_ data: [ImageGroup]) -> ())? )
}


extension DataLoader: ImageSource {
    var loadedImageLimit: Int {
        maxLoadedImageGroups
    }
    
    /// Wraps around fetchImages(inRange: withContext:) to avoid exposing `context`
    /// - Parameter coordRange: Two (lat, long) coordinate pairs
    /// - Returns: An array of all points in the bounding box
    func getImages(inRegion region: MKCoordinateRegion) -> [ImageGroup] {
        do {
            let latDelta = region.span.latitudeDelta / 2,
                lonDelta = region.span.longitudeDelta / 2
            let coordRange = [
                CLLocationCoordinate2D(latitude: region.center.latitude - latDelta, longitude: region.center.longitude - lonDelta),
                CLLocationCoordinate2D(latitude: region.center.latitude + latDelta, longitude: region.center.longitude + lonDelta)
            ]
            let nearbyImageGroups = try fetchImages(inRange: coordRange, withContext: context)
            return nearbyImageGroups ?? []
        } catch {
            print("Dataloader: Error fetching images: \(error)")
            return []
        }
    }
    
    func newImages(
        inRegion region: MKCoordinateRegion,
        withPriorImages prior: [ImageGroup]
    ) -> [ImageGroup] {
        let allImages = getImages(inRegion: region)
        let priorIds = prior.map {
            $0.objectID.hashValue
        }
        
        // Only keep images whose ID DOESN'T exist in the prior image array
        let newImages = allImages.filter {
            !priorIds.contains($0.objectID.hashValue)
        }
        
        return newImages
    }
    
    func testPrivateRequest(
        inRegion region: MKCoordinateRegion,
        completion: ((_ data: [ImageGroup]) -> ())?
    ) {
        let latDelta = region.span.latitudeDelta / 2,
            lonDelta = region.span.longitudeDelta / 2
        let coordRange = [
            CLLocationCoordinate2D(latitude: region.center.latitude - latDelta, longitude: region.center.longitude - lonDelta),
            CLLocationCoordinate2D(latitude: region.center.latitude + latDelta, longitude: region.center.longitude + lonDelta)
        ]
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = context
        privateContext.perform {
            let startTime = Date()
            let data = try? self.fetchImages(inRange: coordRange, withContext: privateContext)
            let copy = data?.map {
                $0.copyWithoutContext()
            }
            print("Async request time: \(-startTime.timeIntervalSinceNow)")
            DispatchQueue.main.async {
                completion?(copy ?? [])
            }
        }
        
    }
}
