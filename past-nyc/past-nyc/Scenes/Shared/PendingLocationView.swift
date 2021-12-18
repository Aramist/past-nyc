//
//  PendingLocationView.swift
//  past-nyc
//
//  Created by Aramis on 12/17/21.
//

import UIKit

class PendingLocationView: UIView {
    
    @IBOutlet var contentView: UIView!
    var locationManager = LocationManager.sharedInstance

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    func initialize() {
        Bundle.main.loadNibNamed(
            "PendingLocationView",
            owner: self,
            options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.widthAnchor.constraint(equalTo: widthAnchor),
            contentView.heightAnchor.constraint(equalTo: heightAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor)
        ])
        layer.cornerRadius = 10.0
        contentView.layer.cornerRadius = 10.0
        
        isOpaque = false
        layer.isOpaque = false
        backgroundColor = .clear
        
        if locationManager.hasAcquiredUserLocation {
            isHidden = true
            return
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didUpdateUserLocation(_:)),
            name: .didReceiveUserLocation,
            object: nil)
    }
    
    @objc func didUpdateUserLocation(_ sender: Notification) {
        isHidden = true
    }

}
