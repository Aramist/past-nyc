//
//  ImageGroupAnnotation.swift
//  past-nyc
//
//  Created by Aramis on 12/4/21.
//

import MapKit


class ImageGroupAnnotation: NSObject, MKAnnotation {
    
    // The exact location of this doesn't matter, as long as it's off-screen
    // This particular point is a Sam's club parking lot in Jersey
    fileprivate static let defaultCoordinate = CLLocationCoordinate2D(latitude: 40.791435, longitude: -74.042862)
    
    var delegate: ImageGroupAnnotationDelegate?
    var wrappedImage: ImageGroup? {
        didSet {
            if let wrappedImage = wrappedImage {
                delegate?.annotation(dataWasReassignedTo: wrappedImage)
            } else {
                delegate?.annotationDataWasRemoved()
            }
        }
    }
    
    override init() {}
    
    public var coordinate: CLLocationCoordinate2D {
        if let wrappedImage = wrappedImage {
            return CLLocationCoordinate2D(latitude: Double(wrappedImage.latitude), longitude: Double(wrappedImage.longitude))
        }
        return ImageGroupAnnotation.defaultCoordinate
    }
    
    public var title: String? { nil }
    public var subtitle: String? { nil }
}

protocol ImageGroupAnnotationDelegate: MKAnnotationView {
    // When called, the delegate should repopulate it's contents to match the indicated view
    func annotation(dataWasReassignedTo data: ImageGroup)
    // When called, the delegate should hide itself and potentially clear any ImageGroup related data
    func annotationDataWasRemoved()
}
