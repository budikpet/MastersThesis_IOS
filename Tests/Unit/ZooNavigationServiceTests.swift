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

class ZooNavigationServiceTests: XCTestCase {

    let realm: Realm = testDependencies.realm
    let zooNavigationService: ZooNavigationServicing = testDependencies.zooNavigationService
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
        let resultPathIds: [Int64] = result!.map { $0.currNode._id }
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
        let resultPathIds: [Int64] = result!.map { $0.currNode._id }
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
        let resultPathIds: [Int64] = result!.map { $0.currNode._id }
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
