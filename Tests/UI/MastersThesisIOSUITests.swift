//
//  MastersThesisIOSUITests.swift
//  MastersThesisIOSUITests
//
//  Created by Petr Budík on 01/05/2021.
//  Copyright © 2021 Petr Budík. All rights reserved.
//

import XCTest

class MastersThesisIOSUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        super.setUp()

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.

        app = XCUIApplication()

        // Then we can use ProcessInfo.processInfo.arguments.contains('--uitesting') in the application to check
        app.launchArguments.append("--uitesting")
    }

    func testFilterIconsChanged() throws {
        // UI tests must launch the application that they test.
        app.launch()

        let lexiconTable = app.tables["LexiconVC_TableView"]
        let filtersTable = app.tables["AnimalFilterVC_TableView"]
        let filtersItem = app.navigationBars.buttons["Filters_NavItem"]

        // Check if in lexicon view
        XCTAssertTrue(lexiconTable.exists)
        XCTAssertTrue(filtersItem.exists)

        filtersItem.tap()

        // Check if in filters view and if filters exist
        XCTAssertTrue(filtersTable.exists)
//        XCTAssert(filtersTable.staticTexts.count > 0)

        // Tap one of the filters
        let filterItem = filtersTable.staticTexts.containing(NSPredicate(format: "label == %@", "Paryby")).firstMatch
        let filterItemCheckmark = filterItem.images["FilterItemCell_CheckMark"]
        XCTAssertTrue(filterItem.exists)
//        XCTAssertTrue(filterItemCheckmark.exists)
//        XCTAssertFalse(filterItemCheckmark.isEnabled)

        filterItem.tap()

//        XCTAssertTrue(filterItemCheckmark.isEnabled)

        // Go back to lexicon view
        app.navigationBars.buttons.element(boundBy: 0).tap()
//
        XCTAssertTrue(lexiconTable.exists)
        XCTAssertTrue(filtersItem.exists)
        XCTAssertEqual(lexiconTable.cells.count, 1)

    }

//    func testLaunchPerformance() throws {
//        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
//            // This measures how long it takes to launch your application.
//            measure(metrics: [XCTApplicationLaunchMetric()]) {
//                XCUIApplication().launch()
//            }
//        }
//    }
}
