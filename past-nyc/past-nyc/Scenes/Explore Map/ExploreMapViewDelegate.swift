//
//  ExploreMapViewDelegate.swift
//  past-nyc
//
//  Created by Aramis on 12/4/21.
//

import Collections
import MapKit

class ExploreMapViewDelegate: NSObject, MKMapViewDelegate {
    
    var imageSource: ImageSource
    // For instantiating and pushing views when necessary
    var navigationController: UINavigationController?
    var storyboard: UIStoryboard?
    
    // The last time we've looped through annotations to find the nearest 5
    var lastVicinityCheckTime = Date().addingTimeInterval(-0.5)
    var lastAsyncUpdate = Date().addingTimeInterval(-0.5)
    // The 5 (or fewer) annotations that have their image popup enabled
    var activeImageAnnotations: [ImageGroupAnnotation] = []
    var annotationQueue: Deque<ImageGroupAnnotation>
    // Same point in the middle of city hall used as a placeholder in the
    // Nearby Images scene
    var userLocation = CLLocationCoordinate2D(latitude: 40.713147, longitude: -74.005961)
    // Flag to avoid mapViewDidChangeVisibleRegion updates while the map is loading
    var mapIsLoaded = false
    // Flag to avoid adding duplicate annotations to the map
    var hasInsertedAnnotations = false
    
    
    
    init(
        withStoryboard storyboard: UIStoryboard?,
        withNavigationController navigationController: UINavigationController?
    ) {
        self.storyboard = storyboard
        self.navigationController = navigationController
        guard let loader = DataLoader.main else {
            fatalError("ExploreMapViewDelegate: Failed to obtain DataLoader instance")
        }
        
        imageSource = loader
        annotationQueue = []
        // After this point, the queue should never persistently change size
        for _ in 0..<imageSource.loadedImageLimit {
            annotationQueue.append(ImageGroupAnnotation())
        }
    }
    
    
    func centerMapAroundUser(_ mapView: MKMapView) {
        let initialRegion = MKCoordinateRegion(
            center: userLocation,
            latitudinalMeters: 400,
            longitudinalMeters: 400)
        mapView.setRegion(initialRegion, animated: true)
        mapViewDidChangeVisibleRegion(mapView)
    }
    
    /// Creates/dequeues an annotationview for ImageGroup annotations
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is ImageGroupAnnotation else {return nil}
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: WrapperAnnotationView.reuseID)
        if annotationView == nil {
            annotationView = WrapperAnnotationView(
                annotation: annotation,
                reuseIdentifier: WrapperAnnotationView.reuseID)
        }
        
        return annotationView
    }
    
    /// Loads and pushes the relevant cluster detail view controller upon selecting a pop-up annotation
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: false)
        guard let imageGroup = view.annotation as? ImageGroup
        else {return}
        
        let vc = storyboard?.instantiateViewController(
            withIdentifier: ClusterDetailViewController.storyboardID)
        guard let vc = vc as? ClusterDetailViewController else {return}
        vc.images = imageGroup.images
        navigationController?.pushViewController(vc, animated: true)
    }
    
    /// See comment on `mapIsLoaded`
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        mapIsLoaded = true
        if !hasInsertedAnnotations {
            hasInsertedAnnotations = true
            // addAnnotations(_:) only accepts arrays
            let annotationArray = annotationQueue.map({ $0 })
            mapView.addAnnotations(annotationArray)
        }
    }
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        guard mapIsLoaded else {return}
        
        attemptUpdateActivePopups(for: mapView)
        asyncLoadNewAnnotations(for: mapView, fromImageSource: imageSource)
    }
    
    /// Taken from https://stackoverflow.com/questions/9270268/convert-mkcoordinateregion-to-mkmaprect
    func MKMapRectForCoordinateRegion(region:MKCoordinateRegion) -> MKMapRect {
        let topLeft = CLLocationCoordinate2D(latitude: region.center.latitude + (region.span.latitudeDelta/2), longitude: region.center.longitude - (region.span.longitudeDelta/2))
        let bottomRight = CLLocationCoordinate2D(latitude: region.center.latitude - (region.span.latitudeDelta/2), longitude: region.center.longitude + (region.span.longitudeDelta/2))
        
        let a = MKMapPoint(topLeft)
        let b = MKMapPoint(bottomRight)
        
        return MKMapRect(origin: MKMapPoint(x:min(a.x,b.x), y:min(a.y,b.y)), size: MKMapSize(width: abs(a.x-b.x), height: abs(a.y-b.y)))
    }
    
    
    /// Finds the annotations nearest to a given point
    /// - Parameters:
    ///   - annotations: Annotations to search through
    ///   - center: Point from which distance is calculated
    ///   - limit: Number of annotations to return
    /// - Returns: `limit` or fewer points that are nearest to the given center point
    func nearestImageGroups(fromSet annotations: Set<AnyHashable>, toPoint center: CLLocationCoordinate2D, limit: Int) -> [ImageGroupAnnotation] {
        let center = MKMapPoint(center)
        let sortedAnnotations: [ImageGroupAnnotation] = annotations.filter {
            $0 is ImageGroupAnnotation
        }.map {
            return $0 as! ImageGroupAnnotation
        }.sorted {
            MKMapPoint($0.coordinate).distance(to: center) < MKMapPoint($1.coordinate).distance(to: center)
        }
        
        if sortedAnnotations.count < limit {
            return sortedAnnotations
        }
        return Array(sortedAnnotations[0..<limit])
    }
    
    
    /// Given two arrays of image groups, determines which were added and removed from the
    /// first to yield the second
    /// These are returned as a list of Ints, corresponding to the indices (within post)
    /// of added annotations and indices (within prior) of removed annotations
    func annotationDifference(
        betweenPriorAnnotations prior: [ImageGroupAnnotation],
        postAnnotations post: [ImageGroupAnnotation]
    ) -> (addedAnnotations: [Int], removedAnnotations: [Int]) {
        let priorIDs = prior.map {
            $0.wrappedImage?.id
        }
        let postIDs = post.map {
            $0.wrappedImage?.id
        }
        
        
        let newImageGroups = post.enumerated().filter {
            // Select for annotations that aren't a part of prior
            $0.1.wrappedImage != nil
            && !priorIDs.contains($0.1.wrappedImage?.id)
            // Left the optional chain in because I don't actually know if Int and Int? instances
            // with the same value will be considered equal
        }.map {
            $0.0  // Returns the index (first element in the enumerated() tuple)
        }
        let removedImageGroups = prior.enumerated().filter {
            // Select for images that aren't in post
            $0.1.wrappedImage != nil
            && !postIDs.contains($0.1.wrappedImage?.id)
        }.map {
            $0.0  // Returns the index (first element in the enumerated() tuple)
        }
        
        return (addedAnnotations: newImageGroups, removedAnnotations: removedImageGroups)
    }
    
    /// Activates the five nearest annotations and ensures the others are deactivated
    fileprivate func attemptUpdateActivePopups(for mapView: MKMapView) {
        guard lastVicinityCheckTime.timeIntervalSinceNow < -0.2 else {return}
        lastVicinityCheckTime = Date()
        print("Annotation count \(mapView.annotations.count)")
        
        let onScreenAnnotations = mapView.annotations(in: MKMapRectForCoordinateRegion(region: mapView.region))
        let closest = nearestImageGroups(fromSet: onScreenAnnotations, toPoint: mapView.centerCoordinate, limit: 5)
        let diff = annotationDifference(betweenPriorAnnotations: activeImageAnnotations, postAnnotations: closest)
        
        // Remove faraway annotations from activeImageAnnotations and deactivate their views
        diff.removedAnnotations.sorted {
            // High-to-low order, so removal of an element doesn't shift the indices
            // of the elements removed later in the for-each loop
            $0 > $1
        }.forEach {
            if let group = mapView.view(for: activeImageAnnotations[$0]) as? WrapperAnnotationView {
                group.deactivate()
            }
            activeImageAnnotations.remove(at: $0)
        }
        
        // Add the new annotations to activeImageAnnotations and activate their views
        diff.addedAnnotations.forEach {
            activeImageAnnotations.append(closest[$0])
            if let group = mapView.view(for: closest[$0]) as? WrapperAnnotationView {
                group.activate()
            }
        }
    }
    
    
    /// Loads new annotations into the map view in an asynchronous fashion. Intended to run
    /// periodically while the user is interacting with the map, creating the effect of
    /// points appearing in real-time
    fileprivate func asyncLoadNewAnnotations(
        for mapView: MKMapView,
        fromImageSource imageSource: ImageSource
    ) {
        guard lastAsyncUpdate.timeIntervalSinceNow < -0.1 else { return }
        lastAsyncUpdate = Date()
        
        // This cast should never fail because of the filter condition
        let priorAnnotations = mapView.annotations.filter( {$0 is ImageGroupAnnotation} ) as? [ImageGroupAnnotation]
        guard let priorAnnotations = priorAnnotations else {
            fatalError("ExploreMapViewDelegate: Failed to cast priorAnnotations to [ImageGroupAnnotation]")
        }
        let priorIDArray = priorAnnotations.filter({ $0.wrappedImage != nil }).map({ $0.wrappedImage!.id })
        let priorIDSet = Set(priorIDArray)
        
        imageSource.asyncNewImages(
            inRegion: mapView.region,
            withPriorImageIDs: priorIDSet
        ) { [weak self] update in
            guard update.count > 0 else { return }
            self?.recycleAnnotations(inserting: update)
        }
    }
    
    /// Recycles the least recently used annotations to present new images to the map
    /// In doing so, we avoid adding/removing annotations from the mapview, while still
    /// accomplishing the goal of presenting new images as the user pans around
    /// - Parameter newData: The new ImageGroups to attach to annotations
    fileprivate func recycleAnnotations(inserting newData: [ImageGroup]) {
        guard newData.count > 0 else { return }
        
        // 1) Dequeue an annotation from the end
        // 2) Update its data
        // 3) Enqueue it back to the beginning
        newData.forEach {
            let recycledAnnotation = annotationQueue.popLast()
            // The queue should always be populated, so this shouldn't ever skip
            guard let recycledAnnotation = recycledAnnotation else { return }
            recycledAnnotation.wrappedImage = $0
            annotationQueue.prepend(recycledAnnotation)
        }
    }
}
