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

    /// Fills all nodes between separate connector nodes that make the shortest path.
    /// - Parameter connectorsPath: The shortest found path made up of connector nodes only.
    /// - Returns: A list of all RoadNodes that make up the shortest path between origin connector node and destination connection node.
    internal func populateShortestPath(connectorsPath: [GraphNode]) -> [RoadNode] {
        var lastConnector: GraphNode = connectorsPath[0]
        var res: [RoadNode] = []

        for connector in connectorsPath {
            if(connector != lastConnector) {
                let sharedRoad = getSharedRoad(connector, lastConnector)
                let (firstIndex, lastIndex) = getRoadIndexes(road: sharedRoad, connector, lastConnector)
                var nodesBetween: [RoadNode] = Array(sharedRoad.nodes[firstIndex...lastIndex])

                if(sharedRoad.nodes[firstIndex]._id != lastConnector._id()) {
                    nodesBetween.reverse()
                }

                nodesBetween.popLast()
                res.append(contentsOf: nodesBetween)
            }

            lastConnector = connector
        }

        res.append(lastConnector.node)

        return res
    }

    /// Finds shortest path between the origin and destination nodes.
    /// - Parameters:
    ///   - origins: A list of connector nodes that are immediately available from the origin point.
    ///   - destinations: A list of connector nodes that are immediately available from the destinaton point.
    ///   - destinationPoint: A tuple (longitude, latitude) of the destination point.
    /// - Returns: A list of connector nodes that make up the shortest path between an origin and a destination connector node.
    internal func computeShortestPath(origins: [RoadNode], destinations: [RoadNode], destinationPoint: (Double, Double)) -> [GraphNode]? {
        var openedNodes: Set<GraphNode> = Set(origins.map { GraphNode(roadNode: $0) })
        var closedNodes: Set<GraphNode> = Set()

        while(openedNodes.isNotEmpty) {
            // Get an opened node with lowest value, put it in closed nodes
            guard let currGraphNode = openedNodes.min(by: {$0.getValue() < $1.getValue() }) else { fatalError("Opened nodes have to contain a node with minimum value") }
            openedNodes.remove(currGraphNode)
            closedNodes.insert(currGraphNode)

            if(destinations.contains(currGraphNode.node)) {
                // Path found, reconstruct it into a list
                return constructPath(from: currGraphNode)
            }

            // Find all connector nodes in same roads as the current node

            for roadId in currGraphNode.node.road_ids {
                guard let road = self.roads.first(where: {$0._id == roadId}) else { fatalError("Node's road has to exist.") }

                for neighbour in road.nodes {
                    if(!neighbour.is_connector) {
                        continue
                    } else if(origins.contains(neighbour)) {
                        continue
                    }

                    let neighbour = GraphNode(roadNode: neighbour)

                    if(closedNodes.contains(neighbour)) {
                        // This node was already checked
                        continue
                    } else {
                        neighbour.distanceFromDestination = calculateDistanceBetween(a: neighbour.getCoords(), b: destinationPoint)
                        neighbour.lastNode = currGraphNode
                        neighbour.distanceFromOrigin = currGraphNode.distanceFromOrigin + calculateDistanceBetween(a: neighbour.getCoords(), b: currGraphNode.getCoords())

                        if(openedNodes.contains(neighbour)) {
                            // Neighbour has already been opened, update values if needed
                            guard let openedNeighbour = openedNodes.first(where: {$0 == neighbour}) else { fatalError("Opened node must exist here") }

                            if(neighbour.getValue() < openedNeighbour.getValue()) {
                                // Current neighbour is better, use it to update openedNeighbours values
                                openedNeighbour.lastNode = neighbour.lastNode
                                openedNeighbour.distanceFromDestination = neighbour.distanceFromDestination
                                openedNeighbour.distanceFromOrigin = neighbour.distanceFromOrigin
                            }
                        } else {
                            // Neighbour is not open
                            openedNodes.insert(neighbour)
                        }
                    }
                }
            }
        }

        // No path found
        return nil
    }
}

// MARK: Helpers

extension ZooNavigationService {

    private func getSharedRoad(_ a: GraphNode, _ b: GraphNode) -> Road {
        guard let roadId = Set(a.node.road_ids).intersection(b.node.road_ids).first else { fatalError("Two adjacent connector nodes must have a shared road") }
        guard let road = roads.first(where: {$0._id == roadId}) else { fatalError("Found road must exist.") }
        return road
    }

    /// Constructs path of connector nodes between origin and destination.
    /// - Parameter destination: The last GraphNode of the found path.
    /// - Returns: GraphNodes list of connector nodes from origin to destination.
    private func constructPath(from destination: GraphNode) -> [GraphNode] {
        var res: [GraphNode] = [destination]
        var node = destination

        while let lastNode = node.lastNode {
            res.append(lastNode)
            node = lastNode
        }

        return res.reversed()
    }

    private func getDistanceBetweenConnectorNodes(road: Road, a: GraphNode, b: GraphNode) -> Double {
        let (firstIndex, lastIndex) = getRoadIndexes(road: road, a, b)

        var distance: Double = 0.0
        var lastNode = road.nodes[firstIndex]
        for currNode in road.nodes[(firstIndex+1)...lastIndex] {
            distance += calculateDistanceBetween(a: (currNode.lon, currNode.lat), b: (lastNode.lon, lastNode.lat))
            lastNode = currNode
        }

        return distance
    }

    private func getRoadIndexes(road: Road, _ a: GraphNode, _ b: GraphNode) -> (Int, Int) {
        guard let aIndex = road.nodes.index(of: a.node),
              let bIndex = road.nodes.index(of: b.node)
        else {
            fatalError("Picked nodes have to be part of the rode.")
        }

        let firstIndex = min(aIndex, bIndex)
        let lastIndex = max(aIndex, bIndex)

        return (firstIndex, lastIndex)
    }

    /// Calculates approximate distance between this and the given point. Uses haversine formula.
    /// - Parameter other: A tuple (longitude, latitude) of point B.
    /// - Parameter currNode: A tuple (longitude, latitude) of point A.
    /// - Returns: Distance between this and the given point in meters.
    private func calculateDistanceBetween(a: (Double, Double), b: (Double, Double)) -> Double {
        /// approximate radius of earth in km
        let earthRadius = 6378.14
        let lon1 = radians(a.0)
        let lat1 = radians(a.1)
        let lon2 = radians(b.0)
        let lat2 = radians(b.1)

        // haversine formula
        let dlon = lon2 - lon1
        let dlat = lat2 - lat1
        let a = pow(sin(dlat / 2), 2) + cos(lat1) * cos(lat2) * pow(sin(dlon / 2), 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadius * c * 1000
    }

    private func radians(_ number: Double) -> Double {
        return number * .pi / 180
    }
}

/**
 A structure representing a node in the road graph used for finding the shortest path.
 */
class GraphNode: Equatable, Hashable {
    let node: RoadNode

    /// Previous node in the path i. e. the node between origin and this node that is the fastest to go through to this node
    var lastNode: GraphNode? = nil

    /// Computed distance from the user's location. Sum of lengths of roads in meters
    var distanceFromOrigin: Double = 0

    /// Computed approximate distance from the picked destination. Used as heuristics for the algorithm
    var distanceFromDestination: Double = 0

    init(roadNode: RoadNode, lastNode: GraphNode? = nil, distanceFromOrigin: Double = 0, distanceFromDestination: Double = 0) {
        self.node = roadNode
        self.lastNode = lastNode
        self.distanceFromOrigin = distanceFromOrigin
        self.distanceFromDestination = distanceFromDestination
    }

    /// Compute the value that is used to determine which node is picked the first.
    /// - Returns: Sum of distance from origin and to destination.
    public func getValue() -> Double {
        return distanceFromOrigin + distanceFromDestination
    }

    public func _id() -> Int64 {
        return node._id
    }

    /// - Returns: A tuple (longitude, latitude).
    public func getCoords() -> (Double, Double) {
        return (node.lon, node.lat)
    }

    static func == (lhs: GraphNode, rhs: GraphNode) -> Bool {
        return lhs.node._id == rhs.node._id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(node._id)
    }
}
