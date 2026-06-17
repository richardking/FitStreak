//
//  FitStreakUITests.swift
//  FitStreakUITests
//
//  Created by Richard King on 6/15/26.
//

import XCTest

final class FitStreakUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // XCUIAutomation Documentation
        // https://developer.apple.com/documentation/xcuiautomation
    }

    @MainActor
    func testLoggingTodayAppearsAndSurvivesRelaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-resetData"]
        app.launch()

        let weights = app.buttons["Weights"]
        XCTAssertTrue(weights.waitForExistence(timeout: 5), "Weights card should be present")
        weights.tap()

        let loggedLabel = app.staticTexts["Logged today ✓"]
        XCTAssertTrue(loggedLabel.waitForExistence(timeout: 2), "Subtitle should switch to 'Logged today ✓' after tapping")

        // Persistence: terminate and relaunch WITHOUT reset — entry should still be on disk.
        app.terminate()
        app.launchArguments = []
        app.launch()

        let loggedLabelAfterRelaunch = app.staticTexts["Logged today ✓"]
        XCTAssertTrue(loggedLabelAfterRelaunch.waitForExistence(timeout: 5), "Logged-today state should survive an app relaunch")
    }

    @MainActor
    func testTappingALoggedCardUnlogsIt() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-resetData"]
        app.launch()

        let weights = app.buttons["Weights"]
        XCTAssertTrue(weights.waitForExistence(timeout: 5))

        // First tap → logged.
        weights.tap()
        XCTAssertTrue(app.staticTexts["Logged today ✓"].waitForExistence(timeout: 2),
                      "First tap should log today")

        // Second tap → unlogged. Subtitle reverts.
        weights.tap()
        XCTAssertTrue(app.staticTexts["Log today to continue"].waitForExistence(timeout: 2),
                      "Second tap on an already-logged card should unlog it")
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
