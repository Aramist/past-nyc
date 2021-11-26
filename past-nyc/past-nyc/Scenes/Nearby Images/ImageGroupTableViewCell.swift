//
//  ImageGroupTableViewCell.swift
//  past-nyc
//
//  Created by Aramis on 11/25/21.
//

import UIKit

class ImageGroupTableViewCell: UITableViewCell {
    
    static let reuseID = "ImageGroupTableViewCell"

    @IBOutlet weak var imageCollectionView: UICollectionView!
    
    fileprivate let sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    var imageGroup: ImageGroup? {
        didSet {
            images = imageGroup?.images
        }
    }
    var images: [HistoricalImage]? {
        didSet {
            imageCollectionView.reloadData()
        }
    }
    
    func assignDelegate() {
        imageCollectionView.delegate = self
        imageCollectionView.dataSource = self
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}

extension ImageGroupTableViewCell: UICollectionViewDataSource {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        return images?.count ?? 0
    }
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HistoricalImageCollectionViewCell.reuseID, for: indexPath)
        guard let cell = cell as? HistoricalImageCollectionViewCell else {
            fatalError("Programmer error: failed to dequeue collectionview cell with reuse id '\(HistoricalImageCollectionViewCell.reuseID)' as HistoricalImageCollectionViewCell")
        }
        
        guard let historicalImage = images?[indexPath.item] else {
            cell.backgroundColor = .richBlack
            return cell
        }
        
        cell.data = historicalImage
        historicalImage.assignThumbnailImage(to: cell.imageView, completion: nil)
        return cell
    }
}

extension ImageGroupTableViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard let historicalImage = imageGroup?.images[indexPath.item] else {
            return CGSize.zero
        }
        
        let availHeight = collectionView.bounds.inset(by: sectionInset).height
        let itemHeight = (availHeight - sectionInset.top - sectionInset.bottom).rounded(.down)
        let itemWidth = historicalImage.aspectRatio * itemHeight
        return CGSize(width: itemWidth, height: itemHeight)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        sectionInset.top
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        sectionInset
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        sectionInset.left
    }
}
