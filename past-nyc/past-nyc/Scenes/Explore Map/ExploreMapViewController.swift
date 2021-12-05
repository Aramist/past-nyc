//
//  ExploreMapViewController.swift
//  past-nyc
//
//  Created by Aramis on 11/25/21.
//

import Collections
import CoreLocation
import MapKit

class ExploreMapViewController: UIViewController {

    @IBOutlet weak var exploreMap: MKMapView!
    // Maintain a strong ref to delegate
    var delegate: ExploreMapViewDelegate?
    // Flag to ensure we don't interfere with the user's map exploration every time
    // their location updates
    var hasUpdatedToUserLocation = false
    // Coordinates for NYC's bounding box
    fileprivate let NYCNorthWestBound = CLLocationCoordinate2D(latitude: 40.9162, longitude: -74.2591)
    fileprivate let NYCSouthEastBound = CLLocationCoordinate2D(latitude: 40.4774, longitude: -73.7002)
    // Max and min field of view for the camera, provided in meters (?)
    fileprivate let minCameraVisualField: Double = 400
    fileprivate let maxCameraVisualField: Double = 10000
    
    
    deinit {
        exploreMap.delegate = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureAppearance()
        
        delegate = ExploreMapViewDelegate(withStoryboard: storyboard, withNavigationController: navigationController)
        exploreMap.delegate = delegate
        
        assignBoundingBox(to: exploreMap)
        delegate?.centerMapAroundUser(exploreMap)
        
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
        delegate?.mapViewDidChangeVisibleRegion(exploreMap)
    }
    
    fileprivate func configureAppearance() {
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.honeydew]
        navigationController?.navigationBar.backgroundColor = .imperialRed
    }
    
    fileprivate func assignBoundingBox(to mapView: MKMapView) {
        let center = CLLocationCoordinate2D(
            latitude: (NYCNorthWestBound.latitude + NYCSouthEastBound.latitude) / 2,
            longitude: (NYCNorthWestBound.longitude + NYCSouthEastBound.longitude) / 2)
        let latDelta = abs(NYCNorthWestBound.latitude - NYCSouthEastBound.latitude)
        let lonDelta = abs(NYCNorthWestBound.longitude - NYCSouthEastBound.longitude)
        let coordSpan = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        let boundary = MKCoordinateRegion(center: center, span: coordSpan)
        mapView.setCameraBoundary(
            MKMapView.CameraBoundary(coordinateRegion: boundary),
            animated: false)
        mapView.setCameraZoomRange(
            MKMapView.CameraZoomRange(
                minCenterCoordinateDistance: minCameraVisualField,
                maxCenterCoordinateDistance: maxCameraVisualField),
            animated: false)
    }
}


// MARK: Location Delegate
extension ExploreMapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !hasUpdatedToUserLocation else { return }
        hasUpdatedToUserLocation = true
        
        if let userLocation = locations.first {
            delegate?.userLocation = userLocation.coordinate
            delegate?.centerMapAroundUser(exploreMap)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed: \(error)")
    }
}
