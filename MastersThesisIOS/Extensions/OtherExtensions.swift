//
//  OtherExtensions.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 04/04/2021.
//  Copyright © 2021 Petr Budík. All rights reserved.
//

import UIKit
import ReactiveSwift
import CoreLocation

public extension Reactive where Base: UISearchBar {

    /// Sends true if the search bar was opened. Sends false if the search bar was cancelled.
    var visibility: Signal<Bool, Never> {
        Signal.merge(base.reactive.textDidBeginEditing.map() { _ in true }, base.reactive.textDidEndEditing.map() { _ in false })
    }
}

extension Bundle {
    /**
     A resources bundle used by this application.
     */
    public static let resources: Bundle = {
        guard let bundle = Bundle(identifier: Bundle.main.bundleIdentifier ?? "cz.budikpet.ZooPrague") else {
            fatalError("Resources bundle must exist.")
        }

        return bundle
    }()
}

extension CLLocationCoordinate2D {

    /// Get distance between two points
    ///
    /// - Parameters:
    ///   - a: first point
    ///   - b: second point
    /// - Returns: the distance in meters
    static func distance(a: CLLocationCoordinate2D, b: CLLocationCoordinate2D) -> CLLocationDistance {
        let a = CLLocation(latitude: a.latitude, longitude: a.longitude)
        let b = CLLocation(latitude: b.latitude, longitude: b.longitude)
        return a.distance(from: b)
    }
}

// Declare `+` operator overload function
func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

// Declare `-` operator overload function
func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

public extension UIButton {
    func setBackgroundColor(color: UIColor, forState: UIControl.State) {
        self.clipsToBounds = true  // add this to maintain corner radius
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(color.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
            let colorImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            self.setBackgroundImage(colorImage, for: forState)
        }
    }

    func alignTextBelow(padding: CGFloat = 6.0) {
        guard
            let imageViewSize = self.imageView?.frame.size,
            let titleLabelSize = self.titleLabel?.frame.size else {
            return
        }

        let totalHeight = imageViewSize.height + titleLabelSize.height + padding

        self.imageEdgeInsets = UIEdgeInsets(
            top: -2*(titleLabelSize.height + padding),
            left: 0.0,
            bottom: 0.0,
            right: -titleLabelSize.width
        )

        self.titleEdgeInsets = UIEdgeInsets(
            top: 0.0,
            left: -imageViewSize.width,
            bottom: 0.0,
            right: 0.0
        )

        self.contentEdgeInsets = UIEdgeInsets(
            top: 2*(titleLabelSize.height + padding),
            left: 0.0,
            bottom: padding,
            right: 0.0
        )
    }
}

extension URL {

    /// A URL to the default documents directory.
    static var documents: URL {
        return FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
