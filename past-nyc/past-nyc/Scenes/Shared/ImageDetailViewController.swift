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
        
        imageDescriptionLabel.text = annotation.photoDescription
        fullImage.addConstraint(
            fullImage.widthAnchor.constraint(equalTo: fullImage.heightAnchor, multiplier: annotation.aspectRatio)
        )
        annotation.assignFullImage(to: fullImage, completion: nil)
    }

}
