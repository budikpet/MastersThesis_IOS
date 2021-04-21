//
//  UnitTests.swift
//  UnitTests
//
//  Created by Petr Budík on 21/04/2021.
//

import XCTest
import ReactiveSwift
@testable import MastersThesisIOS

class ZooNavigatorServiceTests: XCTestCase {

    let testRealmDbManager: RealmDBManaging = testDependencies.realmDBManager

    override func setUp() {
        super.setUp()
        testDependencies.testRealmInitializer.updateRealm()
        print("Test")
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertTrue(true)
    }

//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
