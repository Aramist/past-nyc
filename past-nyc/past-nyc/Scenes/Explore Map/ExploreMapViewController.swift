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
    var delegate: ExploreMapDelegate?
    fileprivate let locationManager = LocationManager.sharedInstance
    
    // Coordinates for NYC's bounding box
    fileprivate let NYCNorthWestBound = CLLocationCoordinate2D(latitude: 40.9162, longitude: -74.2591)
    fileprivate let NYCSouthEastBound = CLLocationCoordinate2D(latitude: 40.4774, longitude: -73.7002)
    // Max and min field of view for the camera, provided in meters
    fileprivate let minCameraVisualField: Double = 400
    fileprivate let maxCameraVisualField: Double = 10000
    
    deinit {
        // The actual delegate isn't deinitializing until this deinitializes,
        // since this is the only strong ref to the delegate, so this has the
        // same effect as placing it in the delegate (where it really shold be
        // for readability
        exploreMap.delegate = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureAppearance()

        delegate = ExploreMapDelegate(self)
        exploreMap.delegate = delegate
        
        assignBoundingBox(to: exploreMap)
        
        centerMapAroundUser()
        exploreMap.register(
            WrapperAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: WrapperAnnotationView.reuseID)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveLocationNotification), name: nil, object: locationManager)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        delegate?.mapViewDidChangeVisibleRegion(exploreMap)
    }
    
    @objc func didReceiveLocationNotification() {
        centerMapAroundUser()
    }
    
    fileprivate func configureAppearance() {
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.honeydew]
        navigationController?.navigationBar.backgroundColor = .imperialRed
    }
    
    fileprivate func centerMapAroundUser() {
        let initialRegion = MKCoordinateRegion(
            center: locationManager.userLocation ?? locationManager.defaultLocation,
            latitudinalMeters: 400,
            longitudinalMeters: 400)
        exploreMap.setRegion(initialRegion, animated: true)
        delegate?.mapViewDidChangeVisibleRegion(exploreMap)
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
