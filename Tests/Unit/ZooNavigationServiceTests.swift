//
//  UnitTests.swift
//  UnitTests
//
//  Created by Petr Budík on 21/04/2021.
//

import XCTest
import ReactiveSwift
import RealmSwift
@testable import MastersThesisIOS

class PopulateShortestPathTests: XCTestCase {

    let realm: Realm = testDependencies.realm
    let zooNavigationService: ZooNavigationService = ZooNavigationService(dependencies: testDependencies)

    lazy var roadNodes: Results<RoadNode> = {
        return realm.objects(RoadNode.self)
    }()
    lazy var roads: Results<Road> = {
        return realm.objects(Road.self)
    }()

    override func setUp() {
        super.setUp()
        testDependencies.testRealmInitializer.updateRealm()
        self.continueAfterFailure = false
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    //swiftlint:disable trailing_whitespace
    func testShortPath() {
        // Prepare
        let connectorNodesPath: [GraphNode] = [531401381, 999606680, 281647716]
            .map { [weak self] id in
                guard let self = self else { fatalError("Self is nil") }
                guard let node = self.roadNodes.first(where: {$0._id == id}) else { fatalError("Test node not found.") }
                return node
            }
            .map { GraphNode(roadNode: $0) }

//        let destination = GraphNode(roadNode: destinationNode)
//        let origin = GraphNode(roadNode: originNode, destination: destinationNode)

        // Do
        let result = zooNavigationService.populateShortestPath(connectorsPath: connectorNodesPath)
        
        // Assert
        let resultPathIds: [Int64] = result.map { $0._id }
        let expectedResults: [Int64] = [531401381, 382975826, 436123425, 168300856, 520661986, 999606680, 703121452, 971219131, 957693158, 501460275, 900690472, 141267973, 281647716]
        
        XCTAssertEqual(resultPathIds.count, expectedResults.count)
        XCTAssertTrue(expectedResults.elementsEqual(resultPathIds))
    }
    
    //swiftlint:disable trailing_whitespace
    func testMediumPath() {
        // Prepare
        let connectorNodesPath: [GraphNode] = [784448524, 590844987, 524226363, 269005178, 739676219, 190907276]
            .map { [weak self] id in
                guard let self = self else { fatalError("Self is nil") }
                guard let node = self.roadNodes.first(where: {$0._id == id}) else { fatalError("Test node not found.") }
                return node
            }
            .map { GraphNode(roadNode: $0) }

//        let destination = GraphNode(roadNode: destinationNode)
//        let origin = GraphNode(roadNode: originNode, destination: destinationNode)

        // Do
        let result = zooNavigationService.populateShortestPath(connectorsPath: connectorNodesPath)
        
        // Assert
        let resultPathIds: [Int64] = result.map { $0._id }
        let expectedResults: [Int64] = [784448524, 520984713, 893256765, 887511548, 590844987, 223488993, 843346703, 329154370, 336872439, 524226363, 269005178, 739676219, 669070785, 35708408, 190907276]
        
        XCTAssertEqual(resultPathIds.count, expectedResults.count)
        XCTAssertTrue(expectedResults.elementsEqual(resultPathIds))
    }

//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}

class ComputeShortestPathTests: XCTestCase {

    let realm: Realm = testDependencies.realm
    let zooNavigationService: ZooNavigationService = ZooNavigationService(dependencies: testDependencies)
    
    lazy var roadNodes: Results<RoadNode> = {
        return realm.objects(RoadNode.self)
    }()
    lazy var roads: Results<Road> = {
        return realm.objects(Road.self)
    }()

    override func setUp() {
        super.setUp()
        testDependencies.testRealmInitializer.updateRealm()
        self.continueAfterFailure = false
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    //swiftlint:disable trailing_whitespace
    func testShortPath() {
        // Prepare
        guard let destinationNode = roadNodes.first(where: {$0._id == 281647716}) else {
            XCTAssert(false, "Destination node not found in the Realm DB.")
            return
        }
        
        guard let originNode = roadNodes.first(where: {$0._id == 531401381}) else {
            XCTAssert(false, "Origin node not found in the Realm DB.")
            return
        }

//        let destination = GraphNode(roadNode: destinationNode)
//        let origin = GraphNode(roadNode: originNode, destination: destinationNode)

        // Do
        let result = zooNavigationService.computeShortestPath(origins: [originNode], destinations: [destinationNode], destinationPoint: (14.40813, 50.11502))
        
        // Assert
        XCTAssertNotNil(result)
        
        // swiftlint:disable force_unwrapping
        let resultPathIds: [Int64] = result!.map { $0.node._id }
        let expectedResults: [Int64] = [531401381, 999606680, 281647716]
        
        XCTAssertEqual(resultPathIds.count, expectedResults.count)
        XCTAssertTrue(expectedResults.elementsEqual(resultPathIds))
    }
    
    //swiftlint:disable trailing_whitespace
    func testMediumPath() {
        // Prepare
        guard let destinationNode = roadNodes.first(where: {$0._id == 190907276}) else {
            XCTAssert(false, "Destination node not found in the Realm DB.")
            return
        }
        
        guard let originNode = roadNodes.first(where: {$0._id == 784448524}) else {
            XCTAssert(false, "Origin node not found in the Realm DB.")
            return
        }

//        let destination = GraphNode(roadNode: destinationNode)
//        let origin = GraphNode(roadNode: originNode, destination: destinationNode)

        // Do
        let result = zooNavigationService.computeShortestPath(origins: [originNode], destinations: [destinationNode], destinationPoint: (14.40362, 50.11675))
        
        // Assert
        XCTAssertNotNil(result)
        
        // swiftlint:disable force_unwrapping
        let resultPathIds: [Int64] = result!.map { $0.node._id }
        let expectedResults: [Int64] = [784448524, 590844987, 524226363, 269005178, 739676219, 190907276]
        
        XCTAssertEqual(resultPathIds.count, expectedResults.count)
        XCTAssertTrue(expectedResults.elementsEqual(resultPathIds))
    }
    
    //swiftlint:disable trailing_whitespace
    func testMultipleOriginsDestinations() {
        // From (14.40265, 50.11817) to (14.40323, 50.11667)
        // Prepare
        let destinationConnectors: [Int64] = [204519474, 771864649]
        let destinations = Array(roadNodes.filter({ (node: RoadNode) in destinationConnectors.contains(node._id) }))
        
        let originConnectors: [Int64] = [986638646, 24689895, 2374223, 292562085]
        let origins = Array(roadNodes.filter({ (node: RoadNode) in originConnectors.contains(node._id) }))

//        let destination = GraphNode(roadNode: destinationNode)
//        let origin = GraphNode(roadNode: originNode, destination: destinationNode)

        // Do
        let result = zooNavigationService.computeShortestPath(origins: origins, destinations: destinations, destinationPoint: (14.40323, 50.11667))
        
        // Assert
        XCTAssertNotNil(result)
        
        // swiftlint:disable force_unwrapping
        let resultPathIds: [Int64] = result!.map { $0.node._id }
        let expectedResults: [Int64] = [292562085, 763606006, 190907276, 204519474]
        
        XCTAssertEqual(resultPathIds.count, expectedResults.count)
        XCTAssertTrue(expectedResults.elementsEqual(resultPathIds))
    }
    
    func testNotFound() {
        // Trying to navigate to the other side of Vltava which is not possible
        // Prepare
        let destinationConnectors: [Int64] = [420903310]
        let destinations = Array(roadNodes.filter({ (node: RoadNode) in destinationConnectors.contains(node._id) }))
        
        let originConnectors: [Int64] = [986638646, 24689895, 2374223, 292562085]
        let origins = Array(roadNodes.filter({ (node: RoadNode) in originConnectors.contains(node._id) }))

//        let destination = GraphNode(roadNode: destinationNode)
//        let origin = GraphNode(roadNode: originNode, destination: destinationNode)

        // Do
        let result = zooNavigationService.computeShortestPath(origins: origins, destinations: destinations, destinationPoint: (14.39537, 50.11171))
        
        // Assert
        XCTAssertNil(result)
    }

//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
