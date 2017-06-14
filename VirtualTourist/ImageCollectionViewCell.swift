//
//  ImageCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Dustin Howell on 6/13/17.
//  Copyright © 2017 Dustin Howell. All rights reserved.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    private var activityIndictor: UIActivityIndicatorView?
    
    func configureWithImage(image: UIImage?) {
        if let image = image {
            imageView.image = image
            imageView.alpha = 1
            if let indicator = activityIndictor {
                indicator.stopAnimating()
                indicator.removeFromSuperview()
                activityIndictor = nil
            }
        } else {
            imageView.image = nil
            imageView.alpha = 0.3
            if let indicator = activityIndictor, !indicator.isAnimating {
                indicator.startAnimating()
            } else {
                activityIndictor = showActivityIndicator(onView: imageView, withColor: .black, isLarge: true)
            }
        }
    }
    
    private func showActivityIndicator(onView view: UIView, withColor color: UIColor = UIColor.black, isLarge: Bool = true) -> UIActivityIndicatorView {
        let halfx = view.bounds.width / 2
        let halfy = view.bounds.height / 2
        let lesserLength = min(halfx, halfy)
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: lesserLength, height: lesserLength))
        activityIndicator.activityIndicatorViewStyle = isLarge ? .whiteLarge : .white
        activityIndicator.color = color
        executeOnMain {
            view.alpha = 0.3
            view.addSubview(activityIndicator)
            view.bringSubview(toFront: activityIndicator)
            activityIndicator.center = CGPoint(x: halfx, y: halfy)
            activityIndicator.startAnimating()
        }
        return activityIndicator
    }
    
}
