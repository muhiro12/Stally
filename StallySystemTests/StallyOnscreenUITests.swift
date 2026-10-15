import XCTest

/// Verifies native navigation and menu identity with disposable in-memory Items.
final class StallyOnscreenUITests: XCTestCase {
    @MainActor
    func testDetailContextFollowsTabSelectionAndConfirmedDeletion() {
        let app = launchCollection(route: "itemDetail")
        defer {
            app.terminate()
        }
        XCTAssertTrue(app.navigationBars["Black Wool Coat"].waitForExistence(timeout: 10))
        capture(app, name: "primary-detail")

        // Adaptive navigation can place destination and Back buttons outside bars.
        app.buttons["Insights"].tap()
        XCTAssertTrue(app.navigationBars["Insights"].waitForExistence(timeout: 5))
        capture(app, name: "unrelated-insights")
        app.buttons["Library"].tap()
        XCTAssertTrue(app.navigationBars["Black Wool Coat"].waitForExistence(timeout: 5))
        app.buttons["BackButton"].tap()
        XCTAssertTrue(app.navigationBars["Library"].waitForExistence(timeout: 5))

        let search = app.searchFields.firstMatch
        if !search.exists {
            app.swipeDown()
        }
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("Canvas Tote")
        app.staticTexts["Canvas Tote"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Canvas Tote"].waitForExistence(timeout: 5))
        let delete = app.buttons["Delete Item"].firstMatch
        for _ in 0..<5 where !delete.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(delete.isHittable)
        delete.tap()
        let confirmation = app.alerts["Delete Item?"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
        confirmation.buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["Canvas Tote"].exists)
        delete.tap()
        confirmation.buttons["Delete Item"].tap()
        XCTAssertTrue(app.navigationBars["Library"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Canvas Tote"].exists)
        capture(app, name: "deleted-detail-returned-to-library")
    }

    @MainActor
    func testContextAndOrdinaryMenusKeepTheEditedItem() {
        let app = launchCollection(route: "library")
        defer {
            app.terminate()
        }
        XCTAssertTrue(app.navigationBars["Library"].waitForExistence(timeout: 10))
        let search = app.searchFields.firstMatch
        if !search.exists {
            app.swipeDown()
        }
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("Home")
        let row = app.staticTexts["Home"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.press(forDuration: 1)
        XCTAssertTrue(app.buttons["Share Time Together"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Mark Today"].exists)
        capture(app, name: "non-mark-context-menu")
        app.buttons["Edit Item"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Edit Item"].waitForExistence(timeout: 5))
        let name = app.textFields["Name"]
        name.tap()
        name.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: "Home".count) + "Context Home")
        app.buttons["Save"].tap()
        let editedRow = app.staticTexts["Context Home"].firstMatch
        XCTAssertTrue(editedRow.waitForExistence(timeout: 5))
        editedRow.tap()
        XCTAssertTrue(app.navigationBars["Context Home"].waitForExistence(timeout: 5))
        app.buttons["Item Actions"].tap()
        XCTAssertTrue(app.buttons["Share Time Together"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Mark Today"].exists)
        capture(app, name: "edited-item-ordinary-menu")
        app.buttons["Edit Item"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Edit Item"].waitForExistence(timeout: 5))
        XCTAssertEqual(name.value as? String, "Context Home")
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["Context Home"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func launchCollection(route: String) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "--stally-preview-scenario", "integration", "--stally-preview-route", route,
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US"
        ]
        app.launch()
        return app
    }

    @MainActor
    private func capture(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
