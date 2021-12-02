//
//  NearbyImagesViewController.swift
//  past-nyc
//
//  Created by Aramis on 11/25/21.
//

import CoreLocation
import UIKit
import MapKit

class NearbyImagesViewController: UIViewController {
    
    @IBOutlet weak var imageGroupTable: UITableView!
    
    fileprivate var nearbyImages: [ImageGroup]?
    fileprivate var imageSource: ImageSource?
    fileprivate let locationManager = LocationManager.sharedInstance
    
    let searchRadius: Double = 1000.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageSource = DataLoader.sharedInstance
        
        imageGroupTable.delegate = self
        imageGroupTable.dataSource = self
        // TODO: Implement some kind of animation for notifying the user that we are
        // waiting for the device to get their location
        loadTableData()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(loadTableData),
            name: nil,
            object: locationManager)
    }
    
    func configureAppearance() {
        view.backgroundColor = .richBlack
        imageGroupTable.backgroundColor = .richBlack
        
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.honeydew]
        navigationController?.navigationBar.backgroundColor = .imperialRed
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let detail = segue.destination as? ImageDetailViewController,
           let sender = sender as? HistoricalImageCollectionViewCell {
            // sender (Collection View Cell) gets its data set in the cellForItemAt method
            // of the table view cell's extension
            detail.data = sender.data
        }
    }
    
    
    @objc func loadTableData() {
        // The plan is for this class to act as a delegate/datasource for the table
        // And for each cell (row) in the table to act as a delegate/datasource for its
        // child collection view
        
        // As such, the data is distributed as follows:
        //  - This class maintains an array of ImageGroups
        //  - The table cell (row) instances each maintain a single ImageGroup
        //  - The collection cell (column?) instances each maintain a single HistoricalImage
        
        // The end result is several rows of individually (horizontally) scrollable
        // content, similar to the Spotify home page

        let currentLocation = locationManager.userLocation ?? locationManager.defaultLocation
        let searchRegion = regionFromCoordinate(currentLocation, withRadius: searchRadius)
        let userMapPoint = MKMapPoint(currentLocation)
        nearbyImages = imageSource?.getImages(inRegion: searchRegion).sorted {
            MKMapPoint($0.coordinate).distance(to: userMapPoint) < MKMapPoint($1.coordinate).distance(to: userMapPoint)
        }
        
        imageGroupTable.reloadData()
    }
    
    fileprivate func regionFromCoordinate(_ coordinate: CLLocationCoordinate2D, withRadius radius: Double) -> MKCoordinateRegion{
        
        MKCoordinateRegion(center: coordinate, latitudinalMeters: radius, longitudinalMeters: radius)
    }

}

// MARK: Table View Extns.
extension NearbyImagesViewController: UITableViewDelegate {
//    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        // TODO: Return a view that gives the intersection as a title
//        return nil
//    }
    
    func tableView(
        _ tableView: UITableView,
        titleForHeaderInSection section: Int
    ) -> String? {
        return nearbyImages?[section].sampleImage?.intersection
    }
}

extension NearbyImagesViewController: UITableViewDataSource {
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        // Each ImageGroup is a section, so there's only one row per section
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return nearbyImages?.count ?? 0
    }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ImageGroupTableViewCell.reuseID)
        guard let cell = cell as? ImageGroupTableViewCell else {
            fatalError("Programmer Error: Failed to dequeue table view cell with reuse id: \(ImageGroupTableViewCell.reuseID)")
        }
        
        guard let cellData = nearbyImages?[indexPath.section] else {
            fatalError("Programmer Error: Somehow tableView(_: cellForRowAt) was called with a nil data array.")
        }
        
        cell.imageGroup = cellData
        cell.backgroundColor = .richBlack
        cell.assignDelegate()
        return cell
    }
}
