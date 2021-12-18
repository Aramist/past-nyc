//
//  WrapperAnnotationView.swift
//  past-nyc
//
//  Created by Aramis on 11/25/21.
//

import MapKit

class WrapperAnnotationView: MKAnnotationView {
    
    static let reuseID = "WrapperAnnotationView"

    var radius: CGFloat = 5
    let circle: UIView = {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        v.backgroundColor = .imperialRed
        v.translatesAutoresizingMaskIntoConstraints = false
        
        let inner = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        inner.backgroundColor = .white
        inner.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(inner)
        NSLayoutConstraint.activate([
            inner.widthAnchor.constraint(equalTo: v.widthAnchor, multiplier: 0.5),
            inner.heightAnchor.constraint(equalTo: v.heightAnchor, multiplier: 0.5),
            inner.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            inner.centerYAnchor.constraint(equalTo: v.centerYAnchor)
        ])
        return v
    }()
    
    var childAnnotationView: PopupImageAnnotationView?
    
    // MARK: Inherited methods
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        isHidden = true
        arrangeSubview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForDisplay() {
        super.prepareForDisplay()
        guard let annotation = annotation as? ImageGroup else {return}
        childAnnotationView?.prepareForDisplay(withAnnotation: annotation)
        isEnabled = false
        centerOffset = CGPoint(x: bounds.width / 2, y: -bounds.height / 2)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        childAnnotationView?.prepareForReuse()
        centerOffset = CGPoint.zero
        isHidden = true
    }
    
    // MARK: Non-inherited methods
    func updateOffset() {
        centerOffset = CGPoint(x: bounds.width / 2, y: -bounds.height / 2)
//        isHidden = false
    }

    func activate() {
        childAnnotationView?.show()
        isEnabled = true
    }
    
    func deactivate() {
        childAnnotationView?.hide()
        isEnabled = false
    }
    
    fileprivate func arrangeSubview() {
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(circle)
        NSLayoutConstraint.activate([
            circle.widthAnchor.constraint(equalToConstant: radius * 2),
            circle.heightAnchor.constraint(equalToConstant: radius * 2),
            circle.centerXAnchor.constraint(equalTo: leadingAnchor),
            circle.centerYAnchor.constraint(equalTo: bottomAnchor)
        ])
        circle.layer.cornerRadius = radius
        circle.subviews.first?.layer.cornerRadius = radius / 2
        
        let child = PopupImageAnnotationView()
        childAnnotationView = child
        addSubview(child)
        
        NSLayoutConstraint.activate([
            child.leadingAnchor.constraint(equalTo: leadingAnchor),
            child.bottomAnchor.constraint(equalTo: bottomAnchor),
            child.widthAnchor.constraint(equalTo: widthAnchor),
            child.heightAnchor.constraint(equalTo: heightAnchor)
        ])
    }
}
