//
//  ExploreMapViewController.swift
//  past-nyc
//
//  Created by Aramis on 11/25/21.
//

import CoreLocation
import MapKit

class ExploreMapViewController: UIViewController {

    @IBOutlet weak var exploreMap: MKMapView!
    var imageSource: ImageSource?
    
    // The last time we've looped through annotations to find the nearest 5
    var lastVicinityCheckTime = Date().addingTimeInterval(-5)
    // The 5 (or fewer) annotations that have their image popup enabled
    var activeImageAnnotations: [ImageGroup] = []
    // Same point in the middle of city hall used as a placeholder in the Nearby Images scene
    var userLocation = CLLocationCoordinate2D(latitude: 40.713147, longitude: -74.005961)
    
    deinit {
        exploreMap.delegate = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureAppearance()

        imageSource = DataLoader.main
        exploreMap.delegate = self
        
        centerMapAroundUser()
        exploreMap.register(
            WrapperAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: WrapperAnnotationView.reuseID)
        
        // Setup location manager to get current location
        // Copied from NearbyImagesViewController.swift. Consider editing that
        // too if this ever gets modified
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        // TODO: Is it worth supporting iOS 13
        if #available(iOS 14.0, *) {
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestWhenInUseAuthorization()
            }
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
        locationManager.requestLocation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        mapViewDidChangeVisibleRegion(exploreMap)
    }
    
    fileprivate func configureAppearance() {
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.honeydew]
        navigationController?.navigationBar.backgroundColor = .imperialRed
    }
    
    fileprivate func centerMapAroundUser() {
        let initialRegion = MKCoordinateRegion(
            center: userLocation,
            latitudinalMeters: 400,
            longitudinalMeters: 400)
        exploreMap.setRegion(initialRegion, animated: true)
    }
}


// MARK: Location Delegate
extension ExploreMapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let userLocation = locations.first {
            self.userLocation = userLocation.coordinate
            centerMapAroundUser()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed: \(error)")
    }
}


// MARK: MapView Delegate
extension ExploreMapViewController: MKMapViewDelegate {
    
    /// Creates/dequeues an annotationview for ImageGroup annotations
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is ImageGroup else {return nil}
        
        var annotationView = exploreMap.dequeueReusableAnnotationView(withIdentifier: WrapperAnnotationView.reuseID)
        if annotationView == nil {
            annotationView = WrapperAnnotationView(
                annotation: annotation,
                reuseIdentifier: WrapperAnnotationView.reuseID)
        }
        
        return annotationView
    }
    
    /// Loads and pushes the relevant cluster detail view controller upon selecting a pop-up annotation
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        exploreMap.deselectAnnotation(view.annotation, animated: false)
        guard let imageGroup = view.annotation as? ImageGroup else {return}
        let vc = storyboard?.instantiateViewController(
            withIdentifier: ClusterDetailViewController.storyboardID)
        guard let vc = vc as? ClusterDetailViewController else {return}
        vc.images = imageGroup.images
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        guard let source = imageSource else {return}
        reloadAnnotations(from: source)
    }
    
    /// Activates the five nearest annotations and ensures the others are deactivated
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
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
            if let group = exploreMap.view(for: $0) as? WrapperAnnotationView {
                group.deactivate()
            }
        }
        diff.addedAnnotations.forEach {
            if let group = exploreMap.view(for: $0) as? WrapperAnnotationView {
                group.activate()
            }
        }
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
    fileprivate func reloadAnnotations(from source: ImageSource) {
        guard let priorAnnotations = exploreMap.annotations.filter( {$0 is ImageGroup}) as? [ImageGroup]
        else {
            return // I don't believe this will ever be triggered
        }
        
        let update = source.newImages(inRegion: exploreMap.region, withPriorImages: priorAnnotations)
        exploreMap.addAnnotations(update)
        
        if exploreMap.annotations.count > source.loadedImageLimit {
            cullAnnotations()
        }
    }
    
    /// Removes all annotations greater than 800m from the map center
    fileprivate func cullAnnotations() {
        let farAnnotations = exploreMap.annotations.filter {
            MKMapPoint($0.coordinate).distance(to: MKMapPoint(exploreMap.centerCoordinate)) > 800
        }
        exploreMap.removeAnnotations(farAnnotations)
    }
}
