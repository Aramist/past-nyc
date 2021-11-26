//
//  HistoriclaImageCollectionViewCell.swift
//  past-nyc
//
//  Created by Aramis on 11/25/21.
//

import UIKit

class HistoricalImageCollectionViewCell: UICollectionViewCell {
    
    static let reuseID = "HistoricalImageCollectionViewCell"
    
    @IBOutlet weak var imageView: UIImageView!
    // Referenced here for the sake of passing it to the Detail view through prepare(for:sender)
    var data: HistoricalImage?
    
}
