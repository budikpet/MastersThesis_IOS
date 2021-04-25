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

typealias ShortestPath = [CLLocationCoordinate2D]

protocol HasZooNavigationService {
    var zooNavigationService: ZooNavigationServicing { get }
}

protocol ZooNavigationServiceActions {
    var findShortestPath: Action<(CLLocationCoordinate2D, CLLocationCoordinate2D), ShortestPath, NavigationError> { get }
}

protocol ZooNavigationServicing {
    var actions: ZooNavigationServiceActions { get }
}

/**
 Handles updating of local Realm DB.
 */
final class ZooNavigationService: ZooNavigationServicing, ZooNavigationServiceActions {
    typealias Dependencies = HasRealm
    private let realm: Realm

    // MARK: Actions
    internal var actions: ZooNavigationServiceActions { self }

    /// An action that requires (origin, destination) points, returns shortest path
    internal lazy var findShortestPath: Action<(CLLocationCoordinate2D, CLLocationCoordinate2D), ShortestPath, NavigationError> = Action { [unowned self] (origin, dest) in
        SignalProducer<ShortestPath, NavigationError> { sink, _ in
            let path = self.findShortestPath(betweenOrigin: (origin.longitude, origin.latitude), andDestination: (dest.longitude, dest.latitude))?
                .map({ (lon, lat) -> CLLocationCoordinate2D in
                    return CLLocationCoordinate2D(latitude: lat, longitude: lon)
                })

            if let path = path {
                sink.send(value: path)
            } else {
                sink.send(error: .notFound)
            }

            sink.sendCompleted()
        }
    }

    // MARK: Local

    private var roadsToken: NotificationToken!
    private var roadNodesToken: NotificationToken!

    private var roads: [DetachedRoad]
    /// All road nodes, used primarily to find the closest point to the non-road point.
    private var roadNodes: [DetachedRoadNode]

    init(dependencies: Dependencies) {
        self.realm = dependencies.realm
        self.roads = Array(realm.objects(Road.self).map { DetachedRoad(using: $0) })
        self.roadNodes = Array(realm.objects(RoadNode.self).map { DetachedRoadNode(using: $0) })

        roadsToken = realm.objects(Road.self).observe { [weak self] (changes: RealmCollectionChange) in
            guard let self = self else { return }
            switch changes {
            case .initial:
                break
            case .update(let updatedValues, _, _, _):
                self.roads = Array(updatedValues).map { DetachedRoad(using: $0) }
                break
            case .error:
                fatalError("Error occured during observation.")
            }
        }

        roadNodesToken = realm.objects(RoadNode.self).observe { [weak self] (changes: RealmCollectionChange) in
            guard let self = self else { return }
            switch changes {
            case .initial:
                break
            case .update(let updatedValues, _, _, _):
                self.roadNodes = Array(updatedValues).map { DetachedRoadNode(using: $0) }
                break
            case .error:
                fatalError("Error occured during observation.")
            }
        }
    }

    deinit {
        roadsToken.invalidate()
        roadNodesToken.invalidate()
    }

    /// Runs the find shortest path algorithm between two points.
    /// - Parameters:
    ///   - origin: Possibly off-road origin point, a tuple (longitude, latitude)
    ///   - dest: Possibly off-road destination point, a tuple (longitude, latitude)
    internal func findShortestPath(betweenOrigin origin: (Double, Double), andDestination dest: (Double, Double)) -> [(Double, Double)]? {
        os_log("Starting finding shortest path between [%f, %f] and [%f, %f]", log: Logger.appLog(), type: .info, origin.0, origin.1, dest.0, dest.1)
        let roadOrigin: RoadPoint = findClosestRoadPoint(fromPoint: origin)
        let roadDest: RoadPoint = findClosestRoadPoint(fromPoint: dest)

        if(roadOrigin.road._id == roadDest.road._id) {
            // User and destination are on the same road
            return createFullShortestPath(originPoint: roadOrigin, destinationPoint: roadDest, [])
        }

        let origins = roadOrigin.road.nodes.filter { $0.is_connector }
        let dests = roadDest.road.nodes.filter { $0.is_connector }

        guard let connectorsPath = computeShortestPath(origins: Array(origins), destinations: Array(dests), destinationPoint: dest)
        else {
            os_log("Found no path between [%f, %f] and [%f, %f]", log: Logger.appLog(), type: .info, origin.0, origin.1, dest.0, dest.1)
            return nil
        }

        os_log("Found path between [%f, %f] and [%f, %f] as follows: [%s]", log: Logger.appLog(), type: .info, origin.0, origin.1, dest.0, dest.1, connectorsPath.map({ "\($0._id())" }).joined(separator: ","))

        let populatedShortestPath = populateShortestPath(connectorsPath: connectorsPath)

        return createFullShortestPath(originPoint: roadOrigin, destinationPoint: roadDest, populatedShortestPath)
    }

    /// Joins paths from originPoint and destinationPoint to computed shortest path.
    /// - Parameters:
    ///   - originPoint: An origin point that is situated on the first road.
    ///   - destinationPoint: A destination point that is situated on the last road.
    ///   - shortestPath: The shortest found path made up of road nodes. It may be empty (for example if origin & destination are on the same road)
    /// - Returns: A list of tuples (longitude, latitude) that make up the shortest path between given origin point and destination point.
    internal func createFullShortestPath(originPoint: RoadPoint, destinationPoint: RoadPoint, _ shortestPath: [DetachedRoadNode]) -> [(Double, Double)] {
        guard let firstConnector = shortestPath.first,
              let lastConnector = shortestPath.last
        else {
            // User and destination are on the same road
            return constructPath(betweenStart: originPoint.coords(), andEnd: destinationPoint.coords(), on: originPoint.road)
        }

        // Create connected line from points to connector nodes.
        var lineFromOrigin = constructPath(betweenStart: originPoint.coords(), andEnd: firstConnector.coords(), on: originPoint.road)
        lineFromOrigin.removeLast()

        var lineToDest = constructPath(betweenStart: lastConnector.coords(), andEnd: destinationPoint.coords(), on: destinationPoint.road)
        lineToDest.removeFirst()

//        os_log("Origin point [%f, %f] on road %d connected to a node %d.", log: Logger.appLog(), type: .info, originPoint.lon, originPoint.lat, originPoint.road._id, nodeConnectedToOrigin._id)
//        os_log("Dest point [%f, %f] on road %d connected to a node %d.", log: Logger.appLog(), type: .info, destinationPoint.lon, destinationPoint.lat, destinationPoint.road._id, nodeConnectedToDest._id)

        let connectedRoad = shortestPath
            .map { ($0.lon, $0.lat) }

        return lineFromOrigin + connectedRoad + lineToDest
    }

    /// Fills all nodes between separate connector nodes that make the shortest path.
    /// - Parameter connectorsPath: The shortest found path made up of connector nodes only.
    /// - Returns: A list of all RoadNodes that make up the shortest path between origin connector node and destination connection node.
    internal func populateShortestPath(connectorsPath: [GraphNode]) -> [DetachedRoadNode] {
        var lastConnector: GraphNode = connectorsPath[0]
        var res: [DetachedRoadNode] = []

        for connector in connectorsPath {
            if(connector != lastConnector) {
                let sharedRoad = getSharedRoad(connector, lastConnector)
                let nodesBetween: [DetachedRoadNode] = getNodesBetween(lastConnector.node, connector.node, on: sharedRoad)
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
    internal func computeShortestPath(origins: [DetachedRoadNode], destinations: [DetachedRoadNode], destinationPoint: (Double, Double)) -> [GraphNode]? {
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
    /// - Parameter point: Possibly off-road point as a tuple (longitude, latitude).
    /// - Returns: Closest point on a road.
    private func findClosestRoadPoint(fromPoint point: (Double, Double)) -> RoadPoint {
        // Find the closest road node.
        let closestNode = roadNodes.map { [weak self] (node) -> (Double, DetachedRoadNode) in
            guard let self = self else { fatalError("Self must exist") }
            let distance = self.computeDistanceBetween(a: point, b: (node.lon, node.lat))
            return (distance, node)
        }
//        .sorted(by: { $0.0 < $1.0 } )
        .min { $0.0 < $1.0 }

        guard let road_ids = closestNode?.1.road_ids else { fatalError("Closest node must exist.") }

        // Find the closest road point using Turf for Swift
        let closestRoadPoint = Array(road_ids).map { [weak self] roadId -> RoadPoint  in
            guard let self = self else { fatalError("Self must exist") }
            guard let road = self.roads.filter({ $0._id == roadId }).first else { fatalError("Closest road must exist") }
            let coords = Array(road.nodes.map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon) })
            guard let closestCoord = LineString(coords).closestCoordinate(to: CLLocationCoordinate2D(latitude: point.1, longitude: point.0))?.coordinate else { fatalError("Closest coordinates must exist.") }
            return RoadPoint(lon: closestCoord.longitude, lat: closestCoord.latitude, road: road)
        }
        .map { [weak self] (roadPoint) -> (Double, RoadPoint) in
            guard let self = self else { fatalError("Self must exist") }
            let distance = self.computeDistanceBetween(a: point, b: roadPoint.coords())
            return (distance, roadPoint)
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
    private func getNodesBetween(_ startingNode: DetachedRoadNode, _ endingNode: DetachedRoadNode, on road: DetachedRoad) -> [DetachedRoadNode] {
        let (firstIndex, lastIndex) = getRoadIndexes(road: road, startingNode, endingNode)
        var nodesBetween: [DetachedRoadNode] = Array(road.nodes[firstIndex...lastIndex])

        if(road.nodes[firstIndex]._id != startingNode._id) {
            nodesBetween.reverse()
        }

        nodesBetween.popLast()
        return nodesBetween
    }

    /// Constructs path on the given road between two points. These points do not need to be road nodes, but need to be somewhere on the road.
    /// - Parameters:
    ///   - origin: A tuple (longitude, latitude) of origin point.
    ///   - dest: A tuple (longitude, latitude) of destination point.
    ///   - road: DetachedRoad both origin and dest points are part of.
    /// - Returns: A list of tuples (longitude, latitude) that is the path on the given road between two points. First/last member of the list match origin/dest points.
    internal func constructPath(betweenStart origin: (Double, Double), andEnd dest: (Double, Double), on road: DetachedRoad) -> [(Double, Double)] {
        let coords = road.nodes
            .map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon) }

        let line = LineString(Array(coords))
        let start = CLLocationCoordinate2D(latitude: origin.1, longitude: origin.0)
        let end = CLLocationCoordinate2D(latitude: dest.1, longitude: dest.0)

        guard let slicedLine = line.sliced(from: start, to: end) else { fatalError("DetachedRoad must exist") }
        var res = slicedLine.coordinates.map { (Double($0.longitude), Double($0.latitude)) }

        if let first = res.first, let last = res.last, (first != origin && last != dest) {
            // If both values are not equal then the list might be reversed
            let firstDist = computeDistanceBetween(a: first, b: origin)
            let lastDist = computeDistanceBetween(a: last, b: origin)
            if(firstDist > lastDist) {
                // First value is further from the origin than the last value meaning that the list is reversed.
                res.reverse()
            }
        }

        return res
    }

    /// - Parameters:
    ///   - a: GraphNode A
    ///   - b: GraphNode B
    /// - Returns: A road which contains both node A and node B.
    private func getSharedRoad(_ a: GraphNode, _ b: GraphNode) -> DetachedRoad {
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

    private func getDistanceBetweenConnectorNodes(road: DetachedRoad, a: GraphNode, b: GraphNode) -> Double {
        let (firstIndex, lastIndex) = getRoadIndexes(road: road, a.node, b.node)

        var distance: Double = 0.0
        var lastNode = road.nodes[firstIndex]
        for currNode in road.nodes[(firstIndex+1)...lastIndex] {
            distance += computeDistanceBetween(a: (currNode.lon, currNode.lat), b: (lastNode.lon, lastNode.lat))
            lastNode = currNode
        }

        return distance
    }

    private func getRoadIndexes(road: DetachedRoad, _ a: DetachedRoadNode, _ b: DetachedRoadNode) -> (Int, Int) {
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
    let node: DetachedRoadNode

    /// Previous node in the path i. e. the node between origin and this node that is the fastest to go through to this node
    var lastNode: GraphNode? = nil

    /// Computed distance from the user's location. Sum of lengths of roads in meters
    var distanceFromOrigin: Double = 0

    /// Computed approximate distance from the picked destination. Used as heuristics for the algorithm
    var distanceFromDestination: Double = 0

    init(roadNode: DetachedRoadNode, lastNode: GraphNode? = nil, distanceFromOrigin: Double = 0, distanceFromDestination: Double = 0) {
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
    let road: DetachedRoad

    public init(coords: (Double, Double), road: DetachedRoad) {
        self.lon = coords.0
        self.lat = coords.1
        self.road = road
    }

    public init(lon: Double, lat: Double, road: DetachedRoad) {
        self.lon = lon
        self.lat = lat
        self.road = road
    }

    public func coords() -> (Double, Double) {
        return (lon, lat)
    }
}

enum NavigationError: Error {
    case notFound
}
