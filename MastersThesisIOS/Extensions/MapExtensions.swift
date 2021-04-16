//
//  MapExtensions.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 14/04/2021.
//  Copyright © 2021 Petr Budík. All rights reserved.
//

import Foundation
import TangramMap

extension TGGeoPolygon {
    func getCenterPoint() -> CLLocationCoordinate2D? {
        guard let outerRing = self.rings.first else { return nil }
        let halfIndex = Int(Int(outerRing.count) / 2)
        let firstPoint: CLLocationCoordinate2D = outerRing.coordinates.pointee
        let halfPoint: CLLocationCoordinate2D = outerRing.coordinates[halfIndex]

        let middleLon = firstPoint.longitude - (firstPoint.longitude - halfPoint.longitude) / 2
        let middleLat = firstPoint.latitude - (firstPoint.latitude - halfPoint.latitude) / 2

        return CLLocationCoordinate2D(latitude: middleLat, longitude: middleLon)
    }
}
