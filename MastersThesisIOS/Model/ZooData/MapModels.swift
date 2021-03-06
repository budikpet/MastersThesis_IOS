//
//  Map.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 09/08/2020.
//  Copyright © 2020 Petr Budík. All rights reserved.
//

import Foundation
import RealmSwift

class Road: Object {
    @objc dynamic public var _id: Int64 = -1
    public let nodes = List<RoadNode>()

    override public static func primaryKey() -> String? {
        return "_id"
    }

    public convenience init(_ detachedRoad: DetachedRoad) {
        self.init()
        self._id = detachedRoad._id

        for node in detachedRoad.nodes {
            self.nodes.append(RoadNode(node))
        }

    }
}

struct DetachedRoad {
    let _id: Int64
    var nodes: [DetachedRoadNode] = []

    // swiftlint:disable force_cast
    init(using dict: [String: Any]) {
        self._id = dict["_id"] as! Int64

        if let geometry = dict["geometry"] as? [String: Any], let type = geometry["type"] as? String {
            if(type == "LineString") {
                let nodeDicts = (geometry["coordinates"] as? Array<[String: Any]>) ?? []
                for nodeDict in nodeDicts {
                    nodes.append(DetachedRoadNode(using: nodeDict))
                }
            }
        }
    }

    init(using road: Road) {
        self._id = road._id
        for node in road.nodes {
            self.nodes.append(DetachedRoadNode(using: node))
        }
    }
}

class RoadNode: Object {
    @objc dynamic public var _id: Int64 = -1
    @objc dynamic public var lon: Double = -1
    @objc dynamic public var lat: Double = -1
    @objc dynamic public var is_connector: Bool = false
    public let road_ids = List<Int64>()

    override public static func primaryKey() -> String? {
        return "_id"
    }

    public convenience init(_ detachedRoadNode: DetachedRoadNode) {
        self.init()
        self._id = detachedRoadNode._id
        self.lon = detachedRoadNode.lon
        self.lat = detachedRoadNode.lat
        self.is_connector = detachedRoadNode.is_connector

        for road_id in detachedRoadNode.road_ids {
            self.road_ids.append(road_id)
        }

    }

    public func coords() -> (Double, Double) {
        return (lon, lat)
    }
}

struct DetachedRoadNode: Equatable {
    let _id: Int64
    let lon: Double
    let lat: Double
    let is_connector: Bool
    var road_ids: [Int64] = []

    // swiftlint:disable force_cast
    init(using dict: [String: Any]) {
        self._id = dict["_id"] as! Int64
        self.lon = (dict["lon"] as? Double) ?? -1.0
        self.lat = (dict["lat"] as? Double) ?? -1.0
        self.is_connector = (dict["is_connector"] as? Bool) ?? false
        self.road_ids = (dict["road_ids"] as? Array<Int64>) ?? []
    }

    init(using node: RoadNode) {
        self._id = node._id
        self.lon = node.lon
        self.lat = node.lat
        self.is_connector = node.is_connector

        for road_id in node.road_ids {
            self.road_ids.append(road_id)
        }
    }

    public func coords() -> (Double, Double) {
        return (lon, lat)
    }

    static func == (lhs: DetachedRoadNode, rhs: DetachedRoadNode) -> Bool {
        return lhs._id == rhs._id
    }
}

struct MapMetadata {
    let metadata: DetachedMetadata
    let roadNodes: [DetachedRoadNode]
    let roads: [DetachedRoad]

    init(using dict: [String: Any]) {
        guard let metadataDict = dict["metadata"] as? [String: Any] else { fatalError("Metadata input does not exist.") }
        guard let roadNodesDicts = dict["nodes"] as? Array<[String: Any]> else { fatalError("Road nodes input does not exist.") }
        guard let roadsDicts = dict["roads"] as? Array<[String: Any]> else { fatalError("Roads input does not exist.") }

        self.metadata = DetachedMetadata(using: metadataDict)
        self.roadNodes = roadNodesDicts.map { DetachedRoadNode(using: $0) }
        self.roads = roadsDicts.map { DetachedRoad(using: $0) }
    }
}

struct Bounds: Decodable {
    var north: Double
    var east: Double
    var south: Double
    var west: Double
}

struct MapConfig: Decodable {
    var bounds: Bounds
    var minZoom: Float
    var maxZoom: Float
    var mbtilesName: String
}
