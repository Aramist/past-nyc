//
//  ExploreMapDelegate.swift
//  past-nyc
//
//  Created by Aramis Tanelus on 3/3/22.
//

import MapKit
import UIKit

class ExploreMapDelegate: NSObject, MKMapViewDelegate {
    
    // I forgot why I wanted this
    weak var exploreMap: ExploreMapViewController?
    var imageSource: ImageSource
    
    // The last time we've looped through annotations to find the nearest 5
    var lastVicinityCheckTime = Date().addingTimeInterval(-0.5)
    var lastAsyncUpdate = Date().addingTimeInterval(-0.5)
    // The 5 (or fewer) annotations that have their image popup enabled
    var activeImageAnnotations: [ImageGroup] = []
    // Flag to avoid mapViewDidChangeVisibleRegion updates while the map is loading
    var mapIsLoaded = false
    
    
    init?(_ parent: ExploreMapViewController) {
        exploreMap = parent
        guard let imageSource = DataLoader.sharedInstance
        else {
            return nil
        }
        self.imageSource = imageSource
    }
    
    
    /// Creates/dequeues an annotationview for ImageGroup annotations
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is ImageGroup else {return nil}
        
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
        guard let imageGroup = view.annotation as? ImageGroup else {return}
        let vc = exploreMap?.storyboard?.instantiateViewController(
            withIdentifier: ClusterDetailViewController.storyboardID)
        guard let vc = vc as? ClusterDetailViewController else {return}
        vc.images = imageGroup.images
        exploreMap?.navigationController?.pushViewController(vc, animated: true)
    }
    
    /// See comment on `mapIsLoaded`
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        mapIsLoaded = true
    }
    
    /// Prevent too many annotations from showing at once, but only after user interaction
    /// is done, to avoid excessive flickering
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        cullAnnotations(for: mapView)
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
    func nearestImageGroups(fromSet annotations: Set<AnyHashable>, toPoint center: CLLocationCoordinate2D, limit: Int) -> [ImageGroup] {
        let center = MKMapPoint(center)
        let sortedAnnotations: [ImageGroup] = annotations.filter {
            $0 is ImageGroup
        }.map {
            return $0 as! ImageGroup
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
    func annotationDifference(betweenPriorAnnotations prior: [ImageGroup], postAnnotations post: [ImageGroup]) -> (addedAnnotations: [ImageGroup], removedAnnotations: [ImageGroup]) {
   
        
        let priorIdHashes = prior.map {
            $0.objectID.hashValue
        }
        let postIdHashes = post.map {
            $0.objectID.hashValue
        }
        
        let newImageGroups = post.filter {
            !priorIdHashes.contains($0.objectID.hashValue)
        }
        let removedImageGroups = prior.filter {
            !postIdHashes.contains($0.objectID.hashValue)
        }
        
        return (addedAnnotations: newImageGroups, removedAnnotations: removedImageGroups)
    }
    
    /// Pushes new annotations to the map when the field of view shifts
    fileprivate func reloadAnnotations(for mapView: MKMapView, from source: ImageSource) {
        guard let priorAnnotations = mapView.annotations.filter( {$0 is ImageGroup}) as? [ImageGroup]
        else {
            return // I don't believe this will ever be triggered
        }
        
        let update = source.newImages(inRegion: mapView.region, withPriorImages: priorAnnotations)
        mapView.addAnnotations(update)
        
        if mapView.annotations.count > source.loadedImageLimit {
            cullAnnotations(for: mapView)
        }
    }
    
    /// Activates the five nearest annotations and ensures the others are deactivated
    fileprivate func attemptUpdateActivePopups(for mapView: MKMapView) {
        guard lastVicinityCheckTime.timeIntervalSinceNow < -0.2 else {return}
        lastVicinityCheckTime = Date()
        
        let onScreenAnnotations = mapView.annotations(in: MKMapRectForCoordinateRegion(region: mapView.region))
        let closest = nearestImageGroups(fromSet: onScreenAnnotations, toPoint: mapView.centerCoordinate, limit: 5)
        let diff = annotationDifference(betweenPriorAnnotations: activeImageAnnotations, postAnnotations: closest)

        activeImageAnnotations.removeAll {
            diff.removedAnnotations.contains($0)
        }
        activeImageAnnotations.append(contentsOf: diff.addedAnnotations)
        
        diff.removedAnnotations.forEach {
            if let group = mapView.view(for: $0) as? WrapperAnnotationView {
                group.deactivate()
            }
        }
        diff.addedAnnotations.forEach {
            if let group = mapView.view(for: $0) as? WrapperAnnotationView {
                group.activate()
            }
        }
    }
    
    /// Removes all annotations greater than 800m from the map center
    fileprivate func cullAnnotations(for mapView: MKMapView) {
        let farAnnotations = mapView.annotations.filter {
            MKMapPoint($0.coordinate).distance(to: MKMapPoint(mapView.centerCoordinate)) > 800
        }
        mapView.removeAnnotations(farAnnotations)
    }
    
    fileprivate func asyncLoadNewAnnotations(
        for mapView: MKMapView,
        fromImageSource imageSource: ImageSource
    ) {
        guard lastAsyncUpdate.timeIntervalSinceNow < -0.1 else {return}
        lastAsyncUpdate = Date()
        
        // This cast should never fail because of the filter condition
        let priorAnnotations = mapView.annotations.filter( {$0 is ImageGroup} ) as! [ImageGroup]
        let priorIDs = Set(priorAnnotations.map({ $0.uniqueID }))
        
        
        imageSource.asyncNewImages(
            inRegion: mapView.region,
            withPriorImageIDs: priorIDs
        ) { [weak mapView] update in
            guard update.count > 0 else { return }
            mapView?.addAnnotations(update)
        }
    }
}
