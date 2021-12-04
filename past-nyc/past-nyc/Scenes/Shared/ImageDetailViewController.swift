//
//  ImageDetailViewController.swift
//  past-nyc
//
//  Created by Aramis on 11/25/21.
//

import UIKit

class ImageDetailViewController: UIViewController {
    
    static let storyboardID = "ImageDetailViewController"
    
    @IBOutlet weak var parentScrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var fullImage: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var imageDescriptionLabel: UILabel!
    
    let imageMaxZoomLevel: CGFloat = 4.0
    let imageMinZoomLevel: CGFloat = 1.0
    var data: HistoricalImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        parentScrollView.backgroundColor = .richBlack
        stackView.backgroundColor = .richBlack
        imageDescriptionLabel.textColor = .white
        
        guard let annotation = data else {
            return
        }
        
        imageDescriptionLabel.text = formatDescription(forImage: annotation)
        dateLabel.text = formatDate(forImage: annotation)
        fullImage.addConstraint(
            fullImage.widthAnchor.constraint(equalTo: fullImage.heightAnchor, multiplier: annotation.aspectRatio)
        )
        annotation.assignFullImage(to: fullImage, completion: nil)
        enablePanAndScale(for: fullImage)
    }
    
    
    /// Many entries contain a string containing multiple years. This function
    /// attempts to retrieve the first
    /// - Parameter annotation: Historical image for which date is retrieved
    /// - Returns: A string containing a single int, a year, or the string "No date"
    fileprivate func formatDate(forImage annotation: HistoricalImage) -> String {
        let date = annotation.date ?? ""
        
        if let firstYearLocation = date.range(of: "[0-9]{4}", options: .regularExpression) {
            return String(date[firstYearLocation])
        }
        
        return "No Date"
    }
    
    /// Many images do not have a description. This function provides feedback to
    /// the user in the event that occurs
    /// - Parameter annotation: Historical image for which date is retrieved
    /// - Returns: A string containing the description or "No description available"
    fileprivate func formatDescription(forImage annotation: HistoricalImage) -> String {
        let desc = annotation.photoDescription ?? ""
        if desc == "" {
            return "No description available."
        }
        return desc
    }
    
    fileprivate func enablePanAndScale(for imageView: UIImageView) {
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        
        doubleTapRecognizer.numberOfTapsRequired = 2
        
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(pinchRecognizer)
        imageView.addGestureRecognizer(panRecognizer)
        imageView.addGestureRecognizer(doubleTapRecognizer)
    }
    
    // MARK: Objc funcs
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        // The stackoverflow answer I'm basing this on performs this check so maybe
        // it's actually necessary
        // Credit: https://stackoverflow.com/a/57192571
        guard let view = gesture.view else { return }
        
        // Attempt to center the scaling about the pinch location
        let gestureLocation = gesture.location(in: view),
            // Gesture location relative to the center of the view (about which transformations are performed)
            pinchLocation = CGPoint(
                x: gestureLocation.x - view.bounds.midX,
                y: gestureLocation.y - view.bounds.midY)
        
        // For some reason, the signs attached to pinchLocation here are the opposite of what I expected
        // Will look into the documentation for these coordinate spaces.
        let joinedTransform = view.transform
            .translatedBy(x: pinchLocation.x, y: pinchLocation.y)
            .scaledBy(x: gesture.scale, y: gesture.scale)
            .translatedBy(x: -pinchLocation.x, y: -pinchLocation.y)
        // Reset the gesture scale to avoid exponential transformations
        gesture.scale = 1.0
        
        // A and D (the top left and lower right elements of a 2D scale transformation matrix
        // represent the scale factor in that dimension. Here, a value less than 1 would indicate
        // the image being smaller than its initial size
        guard joinedTransform.a > imageMinZoomLevel,
              joinedTransform.d > imageMinZoomLevel,
              joinedTransform.a < imageMaxZoomLevel,
              joinedTransform.d < imageMaxZoomLevel
        else {
            return
        }
        
        // Ensure the view's center is still within the parent's bounds,
        // to prevent the image from going off-screen
        let oldTransform = view.transform
        view.transform = joinedTransform
        if !self.view.bounds.contains(CGPoint(x: view.frame.midX, y: view.frame.midY)) {
            view.transform = oldTransform
        }
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        // Modeling this on the pinch handler above
        guard let view = gesture.view else { return }
        
        let translation = gesture.translation(in: view)
        let translationTransform = view.transform.translatedBy(x: translation.x, y: translation.y)
        gesture.setTranslation(.zero, in: view)
        let oldTransform = view.transform
        view.transform = translationTransform
        if !self.view.bounds.contains(CGPoint(x: view.frame.midX, y: view.frame.midY)) {
            view.transform = oldTransform
        }
    }
    
    @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view else { return }
        
        UIView.animate(withDuration: 0.20) {
            view.transform = CGAffineTransform.identity
        }
    }
}

