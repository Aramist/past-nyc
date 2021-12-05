//
//  PopupImageAnnotationView.swift
//  past-nyc
//
//  Created by Aramis on 11/25/21.
//

import MapKit

class PopupImageAnnotationView: UIView {

    let marginWidth: CGFloat = 4
    let cornerPointHeight: CGFloat = 20
    let cornerPointWidth: CGFloat = 10
    let cornerRadius: CGFloat = 4
    let annotationWidth: CGFloat = 90
    let clusterCountRadius: CGFloat = 10
    
    var isShowing: Bool = false
    
    var historicalImage: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    let clusterCountView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        view.layer.cornerRadius = 10
        view.backgroundColor = .imperialRed
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let clusterCountLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.text = ""
        label.textAlignment = .center
        label.numberOfLines = 1
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var aspectRatioConstraint: NSLayoutConstraint?
    var oldDrawLayer: CALayer?
    var previewImage: HistoricalImage?
    var clusterSize: Int = 0
    
    
    // MARK: Inherited methods
    init() {
        super.init(frame: CGRect(x: -200, y: 0, width: annotationWidth, height: annotationWidth))
        isHidden = true
        setupSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        drawBackground(forSize: rect.size)
        super.draw(rect)
    }
    
    func prepareForDisplay(withData annotation: ImageGroup) {
        samplePreviewImage(from: annotation)
        resize()
        showImage()
    }
    
    func prepareForReuse() {
        isHidden = true
        clusterCountView.isHidden = true
        
        if let aspectRatioConstraint = aspectRatioConstraint {
            aspectRatioConstraint.isActive = false
        }
        aspectRatioConstraint = nil
        historicalImage.image = nil
        previewImage = nil
    }
    
    // MARK: Non-inherited methods
    func show() {
        guard !isShowing else {return}
        isShowing = true
        isHidden = false
        
        transform = CGAffineTransform.identity
        let animation = CAKeyframeAnimation(keyPath: "transform.scale")
        animation.values = [0.005, 1.2, 0.8, 1.0]
        animation.keyTimes = [0.0, 0.15, 0.3, 0.60]
        animation.duration = 0.60
        layer.add(animation, forKey: "bounceAnimation")
    }
    
    func hide() {
        guard isShowing else {return}
        isShowing = false
        
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.isHidden = true
        }
        transform = transform.scaledBy(x: 0.005, y: 0.005)
        let animation = CAKeyframeAnimation(keyPath: "transform.scale")
        animation.values = [1.0, 0.00]
        animation.keyTimes = [0.0, 0.30]
        animation.duration = 0.30
        layer.add(animation, forKey: "bounceAnimation")
        CATransaction.commit()
    }
    
    // MARK: Private methods
    fileprivate func setupSubviews() {
        isOpaque = false
        backgroundColor = .clear
        layoutMargins = UIEdgeInsets(top: marginWidth, left: marginWidth, bottom: marginWidth + cornerPointHeight, right: marginWidth)
        translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(historicalImage)
        addSubview(clusterCountView)
        clusterCountView.addSubview(clusterCountLabel)
        clusterCountView.isHidden = true
        
        NSLayoutConstraint.activate([
            // Width should be constant
            widthAnchor.constraint(equalToConstant: annotationWidth),
            // Image should fill layout margins completely
            historicalImage.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            historicalImage.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            historicalImage.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            historicalImage.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            // Cluster count should live in bottom-right corner
            clusterCountLabel.centerXAnchor.constraint(equalTo: clusterCountView.centerXAnchor),
            clusterCountLabel.centerYAnchor.constraint(equalTo: clusterCountView.centerYAnchor),
            clusterCountView.heightAnchor.constraint(equalToConstant: 2 * clusterCountRadius),
            clusterCountView.widthAnchor.constraint(equalTo: clusterCountView.heightAnchor),
            clusterCountView.centerXAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            clusterCountView.centerYAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])
    }
    
    /// When annotation is an ImageGroup, instantiates previewImage with a
    /// random HistoricalImage from the annotation's children
    /// - Parameter annotation: ImageGroup to sample from
    fileprivate func samplePreviewImage(from imageGroup: ImageGroup) {
        previewImage = imageGroup.sampleImage
        clusterSize = imageGroup.imageCount
    }
    
    fileprivate func showImage() {
        guard let previewImage = previewImage else {return}
        
        previewImage.assignThumbnailImage(to: historicalImage) { [weak self] success in
            guard success else {return}
            (self?.superview as? WrapperAnnotationView)?.updateOffset()
        }
        if clusterSize > 0 {
            let clusterText = clusterSize > 9 ? "9+" : "\(clusterSize)"
            self.clusterCountLabel.text = clusterText
            self.clusterCountView.isHidden = false
        }
    }
    
    /// Resizes the parent view to accomodate an image. Does not insert the image into child image view
    /// - Parameter image: Image to use when calculating new size
    fileprivate func resize() {
        guard let image = previewImage else {return}
        
        let height: CGFloat = CGFloat(image.imageHeight),
            width: CGFloat = CGFloat(image.imageWidth)
        let aspectRatio = (height + 2 * marginWidth) / (width + 2 * marginWidth)
        let aspectRatioConstraint = heightAnchor.constraint(equalTo: widthAnchor, multiplier: aspectRatio, constant: cornerPointHeight)
        self.aspectRatioConstraint = aspectRatioConstraint
        aspectRatioConstraint.isActive = true
        let newSize = CGSize(width: annotationWidth, height: annotationWidth * aspectRatio + cornerPointHeight)
        drawBackground(forSize: newSize)
        layer.setNeedsLayout()
        setNeedsDisplay()
    }
    
    /// Draws the background as a white rounded rectangle with a pointed bottom-left corner
    fileprivate func drawBackground(forSize size: CGSize) {
        // Housekeeping
        let drawLayer = CAShapeLayer()
        drawLayer.contentsScale = UIScreen.main.scale
        drawLayer.isOpaque = false  // False because the region right of the pointed corner is transparent
        oldDrawLayer?.removeFromSuperlayer()
        oldDrawLayer = drawLayer
        layer.addSublayer(drawLayer)
        
        let width: CGFloat = size.width,
            height: CGFloat =  size.height
        let path = UIBezierPath()
        path.move(to: CGPoint(x: cornerRadius, y: 0))
        path.addLine(to: CGPoint(x: width - cornerRadius, y: 0))
        path.addArc(
            withCenter: CGPoint(x: width - cornerRadius, y: cornerRadius),
            radius: cornerRadius,
            startAngle: 3 * CGFloat.pi / 2,
            endAngle: 2 * CGFloat.pi,
            clockwise: true)
        path.addLine(to: CGPoint(x: width, y: height - cornerPointHeight - cornerRadius))
        path.addArc(
            withCenter: CGPoint(x: width - cornerRadius, y: height - cornerPointHeight - cornerRadius),
            radius: cornerRadius,
            startAngle: 0,
            endAngle: CGFloat.pi / 2,
            clockwise: true)
        path.addLine(to: CGPoint(x: cornerPointWidth, y: height - cornerPointHeight))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.addArc(
            withCenter: CGPoint(x: cornerRadius, y: cornerRadius),
            radius: cornerRadius,
            startAngle: CGFloat.pi,
            endAngle: 3 * CGFloat.pi / 2,
            clockwise: true)
        
        drawLayer.path = path.cgPath
        drawLayer.fillColor = UIColor.celadonBlue.cgColor
        drawLayer.zPosition = -1
    }
}
