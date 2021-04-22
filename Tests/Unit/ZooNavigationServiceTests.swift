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
        let result = zooNavigationService.computeShortestPath(origins: [originNode], destinations: [destinationNode])
        
        // Assert
        XCTAssertNotNil(result)
        
        // swiftlint:disable force_unwrapping
        let resultPathIds: [Int64] = result!.map { $0.currNode._id }
        let expectedResults: [Int64] = [531401381, 999606680, 999606680, 141267973, 281647716]
        
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
