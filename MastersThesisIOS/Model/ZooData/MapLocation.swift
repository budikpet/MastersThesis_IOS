//
//  MapLocation.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 11/04/2021.
//  Copyright © 2021 Petr Budík. All rights reserved.
//

import Foundation
import RealmSwift

class MapLocation: Object {
    @objc dynamic public var _id: Int64 = -1
    @objc dynamic public var name: String = "-"
    @objc dynamic public var geometry: Geometry? = nil

    override public static func primaryKey() -> String? {
        return "_id"
    }

    public convenience init(using fetchedData: DetachedMapLocation) {
        self.init()
        self._id = fetchedData._id
        self.name = fetchedData.name

        if let geometry = fetchedData.geometry {
            self.geometry = Geometry(using: geometry)
        }
    }
}

class Geometry: Object {
    @objc dynamic public var _type: String = "Point"
    public let coordinates = List<Coordinates2D>()

    public convenience init(using fetchedGeometry: DetachedGeometry) {
        self.init()
        for array2d in fetchedGeometry.coordinates {
            self.coordinates.append(Coordinates2D(using: array2d))
        }
    }
}

class Coordinates2D: Object {
    public let coordinates = List<Coordinates1D>()

    public convenience init(using array: [[Double]]) {
        self.init()

        for array1d in array {
            self.coordinates.append(Coordinates1D(using: array1d))
        }
    }
}

class Coordinates1D: Object {
    public let coordinates = List<Double>()

    public convenience init(using array: [Double]) {
        self.init()
        self.coordinates.append(objectsIn: array)
    }
}

struct DetachedMapLocation {
    let _id: Int64
    let name: String
    let geometry: DetachedGeometry?

    // swiftlint:disable force_cast
    init(using dict: [String: Any]) {
        self._id = dict["_id"] as! Int64
        self.name = (dict["name"] as? String) ?? "-"

        if let geometryDict = dict["geometry"] as? [String: Any] {
            self.geometry = DetachedGeometry(using: geometryDict)
        } else {
            self.geometry = nil
        }
    }
}

struct DetachedGeometry {
    let _type: String
    let coordinates: [[[Double]]]

    init(using dict: [String: Any]) {
        self._type = dict["_type"] as! String
        self.coordinates = (dict["coordinates"] as? [[[Double]]]) ?? [[[]]]
    }
}
