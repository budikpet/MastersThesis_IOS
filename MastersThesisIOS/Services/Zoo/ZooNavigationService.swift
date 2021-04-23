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
import Turf
import CoreLocation
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

    /// Runs the find shortest path algorithm between two points.
    /// - Parameters:
    ///   - origin: Possibly off-road origin point, a tuple (longitude, latitude)
    ///   - dest: Possibly off-road destination point, a tuple (longitude, latitude)
    internal func findShortestPath(betweenOrigin origin: (Double, Double), andDestination dest: (Double, Double)) {
        let roadOrigin = findClosestRoadPoint(fromPoint: origin)
        let roadDest = findClosestRoadPoint(fromPoint: dest)
    }

    /// Joins paths from originPoint and destinationPoint to computed shortest path.
    /// - Parameters:
    ///   - originPoint: An origin point that is situated on the first road.
    ///   - destinationPoint: A destination point that is situated on the last road.
    ///   - shortestPath: The non-empty shortest found path made up of road nodes.
    /// - Returns: A list of tuples (longitude, latitude) that make up the shortest path between given origin point and destination point.
    internal func createFullShortestPath(originPoint: RoadPoint, destinationPoint: RoadPoint, _ shortestPath: [RoadNode]) -> [(Double, Double)] {
        guard let firstConnector = shortestPath.first,
              let lastConnector = shortestPath.last
        else {
            fatalError("Computed shortest paths cannot be empty.")
        }

        let nodeConnectedToOrigin = self.getFirstNodeConnected(to: originPoint, thatsConnectedTo: firstConnector)
        let nodeConnectedToDest = self.getFirstNodeConnected(to: destinationPoint, thatsConnectedTo: lastConnector)
        let nodesFromOrigin: [RoadNode] = self.getNodesBetween(nodeConnectedToOrigin, firstConnector, on: originPoint.road)
        let nodesToDest: [RoadNode] = self.getNodesBetween(nodeConnectedToDest, lastConnector, on: destinationPoint.road)

        let connectedRoad = (nodesFromOrigin + shortestPath + nodesToDest)
            .map { ($0.lon, $0.lat) }

        return [originPoint.coords()] + connectedRoad + [destinationPoint.coords()]
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
                var nodesBetween: [RoadNode] = getNodesBetween(lastConnector.node, connector.node, on: sharedRoad)
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
                        neighbour.distanceFromDestination = computeDistanceBetween(a: neighbour.getCoords(), b: destinationPoint)
                        neighbour.lastNode = currGraphNode
                        neighbour.distanceFromOrigin = currGraphNode.distanceFromOrigin + computeDistanceBetween(a: neighbour.getCoords(), b: currGraphNode.getCoords())

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
    
    /// Finds closest point on a road for the given point.
    /// Firstly looks through all nodes and finds the closest one to the point. Then uses Turf for Swift to find the closest non-node point.
    /// - Parameter origin: Possibly off-road point as a tuple (longitude, latitude).
    /// - Returns: Closest point on a road for the given point as a tuple (longitude, latitude).
    private func findClosestRoadPoint(fromPoint origin: (Double, Double)) -> (Double, Double) {
        // Find the closest road node.
        let closestNode = roadNodes.map { [weak self] (node) -> (Double, RoadNode) in
            guard let self = self else { fatalError("Self must exist") }
            let distance = self.computeDistanceBetween(a: origin, b: (node.lon, node.lat))
            return (distance, node)
        }
//        .sorted(by: { $0.0 < $1.0 } )
        .min { $0.0 < $1.0 }

        guard let road_ids = closestNode?.1.road_ids else { fatalError("Closest node must exist.") }

        // Find the closest road point using Turf for Swift
        let closestRoadPoint = Array(road_ids).map { [weak self] roadId -> LineString.IndexedCoordinate?  in
            guard let self = self else { fatalError("Self must exist") }
            guard let road = self.roads.filter({ $0._id == roadId }).first else { fatalError("Closest road must exist") }
            let coords = Array(road.nodes.map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon) })
            return LineString(coords).closestCoordinate(to: CLLocationCoordinate2D(latitude: origin.1, longitude: origin.0))
        }
        .compactMap { (coord: LineString.IndexedCoordinate?) -> CLLocationCoordinate2D? in
            return coord?.coordinate
        }
        .map { [weak self] (node) -> (Double, (Double, Double)) in
            guard let self = self else { fatalError("Self must exist") }
            let coords = (node.longitude, node.latitude)
            let distance = self.computeDistanceBetween(a: origin, b: coords)
            return (distance, coords)
        }
        .min { $0.0 < $1.0 }

        guard let res = closestRoadPoint?.1 else { fatalError("Closest point on the road must exist.") }
        return res
    }

    /// Computes all nodes between two given connector nodes.
    /// - Parameters:
    ///   - startingNode: The starting node.
    ///   - endingNode: The ending node.
    ///   - road: A road which contains both
    /// - Returns: A list of RoadNodes that starts with startingNode and ends with endingNode.
    private func getNodesBetween(_ startingNode: RoadNode, _ endingNode: RoadNode, on road: Road) -> [RoadNode] {
        let (firstIndex, lastIndex) = getRoadIndexes(road: road, startingNode, endingNode)
        var nodesBetween: [RoadNode] = Array(road.nodes[firstIndex...lastIndex])

        if(road.nodes[firstIndex]._id != startingNode._id) {
            nodesBetween.reverse()
        }

        nodesBetween.popLast()
        return nodesBetween
    }

    /// Finds the first RoadNode that the given point uses to connect to the connector node.
    /// - Parameters:
    ///   - point: A road point that is not part of RoadNodes.
    ///   - connector: A connector node that marks a start/end of the computed shortest path.
    /// - Returns: The first RoadNode that the point connects to to get to the connector node.
    private func getFirstNodeConnected(to point: RoadPoint, thatsConnectedTo connector: RoadNode) -> RoadNode {
        let nodes = point.road.nodes

        for (curr, next) in zip(nodes, nodes.dropFirst()) {
            let currCoords = (curr.lon, curr.lat)
            let nextCoords = (next.lon, next.lat)
            let currPointDiff = (currCoords.0 < point.coords().0, currCoords.1 < point.coords().1)
            let nextPointDiff = (nextCoords.0 < point.coords().0, nextCoords.1 < point.coords().1)
            print("(\(curr._id), \(next._id)): \(currPointDiff) | \(nextPointDiff)")

            if(currPointDiff != nextPointDiff) {
                // The point is between curr and next road node
                let (firstIndex, secondIndex) = getRoadIndexes(road: point.road, curr, next)
                guard let connectorIndex = point.road.nodes.index(of: connector) else { fatalError("Connector index must exist in the road") }

                return secondIndex <= connectorIndex ? nodes[secondIndex] : nodes[firstIndex]
            }
        }

        guard let lastNode = point.road.nodes.last else { fatalError("Last node has to exist.") }

        return lastNode
    }

    /// - Parameters:
    ///   - a: GraphNode A
    ///   - b: GraphNode B
    /// - Returns: A road which contains both node A and node B.
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
        let (firstIndex, lastIndex) = getRoadIndexes(road: road, a.node, b.node)

        var distance: Double = 0.0
        var lastNode = road.nodes[firstIndex]
        for currNode in road.nodes[(firstIndex+1)...lastIndex] {
            distance += computeDistanceBetween(a: (currNode.lon, currNode.lat), b: (lastNode.lon, lastNode.lat))
            lastNode = currNode
        }

        return distance
    }

    private func getRoadIndexes(road: Road, _ a: RoadNode, _ b: RoadNode) -> (Int, Int) {
        guard let aIndex = road.nodes.index(of: a),
              let bIndex = road.nodes.index(of: b)
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
    private func computeDistanceBetween(a: (Double, Double), b: (Double, Double)) -> Double {
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

/*
 A point situated on a road but it isn't one of the road nodes.
 */
struct RoadPoint {
    let lon: Double
    let lat: Double
    let road: Road

    public func coords() -> (Double, Double) {
        return (lon, lat)
    }
}
