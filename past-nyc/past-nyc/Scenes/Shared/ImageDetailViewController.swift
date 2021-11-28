//
//  ImageDetailViewController.swift
//  past-nyc
//
//  Created by Aramis on 11/25/21.
//

import UIKit

class ImageDetailViewController: UIViewController {
    
    static let storyboardID = "ImageDetailViewController"
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var fullImage: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var imageDescriptionLabel: UILabel!
    
    var data: HistoricalImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.backgroundColor = .richBlack
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
}
