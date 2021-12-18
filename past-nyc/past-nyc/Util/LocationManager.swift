//
//  LocationManager.swift
//  past-nyc
//
//  Created by Aramis on 11/30/21.
//

import CoreLocation
import Foundation

class LocationManager: NSObject {
    
    static let sharedInstance = LocationManager()
    
    fileprivate var locationManager: CLLocationManager?
    fileprivate var lastLocation: CLLocationCoordinate2D?
    
    // Some point in the middle of city hall
    let defaultLocation = CLLocationCoordinate2D(latitude: 40.713147, longitude: -74.005961)
    // Prevent outside reassignment
    var userLocation: CLLocationCoordinate2D? { lastLocation }
    
    var hasAcquiredUserLocation = false
    
    fileprivate override init (){
        super.init()
        
        locationManager = CLLocationManager()
        guard let locationManager = locationManager else { return }
        
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
    
    
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !hasAcquiredUserLocation else { return }
        
        if let userLocation = locations.first {
            hasAcquiredUserLocation = true
            lastLocation = userLocation.coordinate
            NotificationCenter.default.post(
                Notification(
                    name: .didReceiveUserLocation,
                    object: nil))
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed: \(error)")
    }
}

extension Notification.Name {
    static let didReceiveUserLocation = Notification.Name("userLocationDidUpdate")
}
