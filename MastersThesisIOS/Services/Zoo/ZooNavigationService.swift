//
//  ZooNavigationService.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 21/04/2021.
//  Copyright © 2021 Petr Budík. All rights reserved.
//

import Foundation
import RealmSwift
import ReactiveSwift
import os.log

protocol HasZooNavigationService {
    var zooNavigationService: ZooNavigationServicing { get }
}

protocol ZooNavigationServiceActions {
}

protocol ZooNavigationServicing {
    var actions: ZooNavigationServiceActions { get }

    func computeShortestPath(origins: [GraphNode], destinations: [GraphNode]) -> [GraphNode]?
}

/**
 Handles updating of local Realm DB.
 */
final class ZooNavigationService: ZooNavigationServicing, ZooNavigationServiceActions {
    typealias Dependencies = HasRealmDBManager
    private let realmDbManager: RealmDBManaging

    // MARK: Actions
    internal var actions: ZooNavigationServiceActions { self }

    // MARK: Local

    private let roads: Results<Road>
    /// All road nodes, used primarily to find the closest point to the non-road point.
    private let roadNodes: Results<RoadNode>
    /// Only connector road nodes, used primarily to find the shortest path.
    private let roadConnectorNodes: LazyFilterSequence<Results<RoadNode>>

    init(dependencies: Dependencies) {
        self.realmDbManager = dependencies.realmDBManager
        self.roads = realmDbManager.realm.objects(Road.self)
        self.roadNodes = realmDbManager.realm.objects(RoadNode.self)
        self.roadConnectorNodes = roadNodes.filter({ $0.is_connector })
    }
}

// MARK: Helpers

extension ZooNavigationService {

    /// Finds shortest path between the origin and destination nodes.
    /// - Parameters:
    ///   - origins: A list of connector nodes that are immediately available from the origin point.
    ///   - destinations: A list of connector nodes that are immediately available from the destinaton point.
    /// - Returns: A list of connector nodes that make up the shortest path between an origin and a destination connector node.
    internal func computeShortestPath(origins: [GraphNode], destinations: [GraphNode]) -> [GraphNode]? {

        return nil
    }
}

/**
 A structure representing a node in the road graph used for finding the shortest path.
 */
struct GraphNode: Equatable {
    let roadNode: RoadNode

    /// Computed distance from the user's location. Sum of lengths of roads
    var distanceFromOrigin: Double

    /// Computed approximate distance from the picked destination. Used as heuristics for the algorithm
    var distanceFromDestination: Double = 0

    init(roadNode: RoadNode, distanceFromOrigin: Double = 0, destination: RoadNode? = nil) {
        self.roadNode = roadNode
        self.distanceFromOrigin = distanceFromOrigin

        if let destination = destination {
            self.distanceFromDestination = self.calculateDistanceFrom(other: destination)
        }
    }

    static func == (lhs: GraphNode, rhs: GraphNode) -> Bool {
        return lhs.roadNode._id == rhs.roadNode._id
    }

    /// Calculates approximate distance between this and the given point. Uses haversine formula.
    /// - Parameter other: Other point.
    /// - Returns: Distance between this and the given point in meters.
    public func calculateDistanceFrom(other: RoadNode) -> Double {
        /// approximate radius of earth in km
        let EARTH_RADIUS = 6378.14
        let lon1 = radians(self.roadNode.lon)
        let lat1 = radians(self.roadNode.lat)
        let lon2 = radians(other.lon)
        let lat2 = radians(other.lat)

        // haversine formula
        let dlon = lon2 - lon1
        let dlat = lat2 - lat1
        let a = pow(sin(dlat / 2), 2) + cos(lat1) * cos(lat2) * pow(sin(dlon / 2), 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return EARTH_RADIUS * c * 1000
    }

    private func radians(_ number: Double) -> Double {
        return number * .pi / 180
    }
}
