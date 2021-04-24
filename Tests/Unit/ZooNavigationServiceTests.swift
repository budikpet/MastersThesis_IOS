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

class FindShortestPathTests: XCTestCase {

    let realm: Realm = testDependencies.realm
    let zooNavigationService: ZooNavigationService = ZooNavigationService(dependencies: testDependencies)

    lazy var roadNodes: Results<RoadNode> = {
        return realm.objects(RoadNode.self)
    }()
    lazy var roads: Results<Road> = {
        return realm.objects(Road.self)
    }()

    override class func setUp() {
        super.setUp()
        testDependencies.testRealmInitializer.updateRealm()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }

    override class func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    //swiftlint:disable trailing_whitespace
    //swiftlint:disable force_unwrapping
    func testSameRoad() {
        // Prepare
        let origin = (14.40461, 50.11837)
        let dest = (14.40217, 50.11876)
        
        // Do
        let result = zooNavigationService.findShortestPath(betweenOrigin: origin, andDestination: dest)
        
        // Assert
        XCTAssertNotNil(result)
        
        let expectedResults: [(Double, Double)] = [360405165, 664050358, 678731707, 154637248, 941428227, 594941651, 969285398, 254636480, 933734346, 295169626, 151508718, 746480045, 871118945]
            .map { [weak self] id in
                guard let self = self else { fatalError("Self is nil") }
                guard let node = self.roadNodes.first(where: {$0._id == id}) else { fatalError("Test node not found.") }
                return (node.lon, node.lat)
            }
        
        // Remove first and last point since these are difficult to predict
        let preparedResult = Array(result![1..<(result!.endIndex)-1])
        
        XCTAssertEqual(preparedResult.count, expectedResults.count)
        XCTAssertTrue(coordinatesEqual(preparedResult, expectedResults))
    }

    //swiftlint:disable trailing_whitespace
    //swiftlint:disable force_unwrapping
    func testNoNewNodes() {
        // Prepare
        let origin = (14.40966, 50.11594)
        let dest = (14.40849, 50.11531)
        
        // Do
        let result = zooNavigationService.findShortestPath(betweenOrigin: origin, andDestination: dest)
        
        // Assert
        XCTAssertNotNil(result)
        
        let expectedResults: [(Double, Double)] = [531401381, 382975826, 436123425, 168300856, 520661986, 999606680, 703121452, 971219131, 957693158, 501460275, 900690472, 141267973, 281647716]
            .map { [weak self] id in
                guard let self = self else { fatalError("Self is nil") }
                guard let node = self.roadNodes.first(where: {$0._id == id}) else { fatalError("Test node not found.") }
                return (node.lon, node.lat)
            }
        
        // Remove first and last point since these are difficult to predict
        let preparedResult = Array(result![1..<(result!.endIndex)-1])
        
        XCTAssertEqual(preparedResult.count, expectedResults.count)
        XCTAssertTrue(coordinatesEqual(preparedResult, expectedResults))
    }
    
    //swiftlint:disable trailing_whitespace
    //swiftlint:disable force_unwrapping
    func testOneAdditionalNodePerPoint() {
        // Prepare
        let origin = (14.40954, 50.11596)
        let dest = (14.40844, 50.11523)
        
        // Do
        let result = zooNavigationService.findShortestPath(betweenOrigin: origin, andDestination: dest)
        
        // Assert
        XCTAssertNotNil(result)
        
        var expectedResults: [(Double, Double)] = [531401381, 382975826, 436123425, 168300856, 520661986, 999606680, 703121452, 971219131, 957693158, 501460275, 900690472, 141267973, 281647716]
            .map { [weak self] id in
                guard let self = self else { fatalError("Self is nil") }
                guard let node = self.roadNodes.first(where: {$0._id == id}) else { fatalError("Test node not found.") }
                return (node.lon, node.lat)
            }
        expectedResults = [(14.4095969, 50.11595227)] + expectedResults + [(14.40845542, 50.11526707)]
        
        // Remove first and last point since these are difficult to predict
        let preparedResult = Array(result![1..<(result!.endIndex)-1])
        
        XCTAssertEqual(preparedResult.count, expectedResults.count)
        XCTAssertTrue(coordinatesEqual(preparedResult, expectedResults))
    }
    
    //swiftlint:disable trailing_whitespace
    //swiftlint:disable force_unwrapping
    func testPointsCloseToWrongNode() {
        // Prepare
        let origin = (14.40962, 50.11595)
        let dest = (14.40848, 50.11528)
        
        // Do
        let result = zooNavigationService.findShortestPath(betweenOrigin: origin, andDestination: dest)
        
        // Assert
        XCTAssertNotNil(result)
        
        let expectedResults: [(Double, Double)] = [531401381, 382975826, 436123425, 168300856, 520661986, 999606680, 703121452, 971219131, 957693158, 501460275, 900690472, 141267973, 281647716]
            .map { [weak self] id in
                guard let self = self else { fatalError("Self is nil") }
                guard let node = self.roadNodes.first(where: {$0._id == id}) else { fatalError("Test node not found.") }
                return (node.lon, node.lat)
            }
        
        // Remove first and last point since these are difficult to predict
        let preparedResult = Array(result![1..<(result!.endIndex)-1])
        
        XCTAssertEqual(preparedResult.count, expectedResults.count)
        XCTAssertTrue(coordinatesEqual(preparedResult, expectedResults))
    }
}

class PopulateShortestPathTests: XCTestCase {

    let realm: Realm = testDependencies.realm
    let zooNavigationService: ZooNavigationService = ZooNavigationService(dependencies: testDependencies)

    lazy var roadNodes: Results<RoadNode> = {
        return realm.objects(RoadNode.self)
    }()
    lazy var roads: Results<Road> = {
        return realm.objects(Road.self)
    }()

    override class func setUp() {
        super.setUp()
        testDependencies.testRealmInitializer.updateRealm()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }

    override class func tearDown() {
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

    override class func setUp() {
        super.setUp()
        testDependencies.testRealmInitializer.updateRealm()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }

    override class func tearDown() {
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

private func coordinatesEqual(_ a: [(Double, Double)], _ b: [(Double, Double)]) -> Bool {
    if(a.count != b.count) {
         return false
    }
    
    for index in 0..<a.count {
        if(a[index].0 != b[index].0 || a[index].1 != b[index].1) {
            return false
        }
    }
    
    return true
}
