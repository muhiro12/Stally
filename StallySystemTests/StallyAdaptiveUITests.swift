import UIKit
import XCTest

/// Protects in-session drafts and presentations while native containers resize.
final class StallyAdaptiveUITests: XCTestCase {
    @MainActor
    func testSelectedDetailAndEditDraftSurviveRotation() {
        let app = launchCollection(route: "itemDetail")
        defer {
            XCUIDevice.shared.orientation = .portrait
            app.terminate()
        }
        XCTAssertTrue(app.navigationBars["Black Wool Coat"].waitForExistence(timeout: 10))
        for orientation in [UIDeviceOrientation.landscapeLeft, .portrait] {
            rotate(app, to: orientation)
            XCTAssertTrue(app.navigationBars["Black Wool Coat"].waitForExistence(timeout: 5))
            capture(app, name: "selected-detail-\(orientation.rawValue)")
        }

        app.buttons["Edit Item"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Edit Item"].waitForExistence(timeout: 5))
        let name = app.textFields["Name"]
        name.tap()
        name.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: "Black Wool Coat".count))
        name.typeText("Retained Edit Draft")
        assertDraftSurvivesRotation(app, name: "Retained Edit Draft", action: "Save")
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["Black Wool Coat"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testCreationDraftAndExportOptionsSurviveRotation() {
        let app = launchCollection(route: "addItem")
        defer {
            XCUIDevice.shared.orientation = .portrait
            app.terminate()
        }
        XCTAssertTrue(app.navigationBars["Add Item"].waitForExistence(timeout: 10))
        let name = app.textFields["Name"]
        name.tap()
        name.typeText("Retained Creation Draft")
        assertDraftSurvivesRotation(app, name: "Retained Creation Draft", action: "Add")
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["Library"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Retained Creation Draft"].exists)

        app.terminate()
        app.launchArguments = arguments(route: "backup")
        app.launch()
        XCTAssertTrue(app.buttons["Export Data"].waitForExistence(timeout: 10))
        app.buttons["Export Data"].tap()
        for orientation in [UIDeviceOrientation.landscapeLeft, .portrait] {
            rotate(app, to: orientation)
            XCTAssertTrue(app.navigationBars["Export Data"].waitForExistence(timeout: 5))
            XCTAssertTrue(app.buttons["Save to Files"].isHittable)
            XCTAssertTrue(app.buttons["Share Data"].isHittable)
            XCTAssertTrue(app.buttons["Done"].isHittable)
            capture(app, name: "export-options-\(orientation.rawValue)")
        }
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["Export Data"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func assertDraftSurvivesRotation(_ app: XCUIApplication, name: String, action: String) {
        for orientation in [UIDeviceOrientation.landscapeLeft, .portrait] {
            rotate(app, to: orientation)
            XCTAssertEqual(app.textFields["Name"].value as? String, name)
            XCTAssertTrue(app.buttons[action].isEnabled)
            XCTAssertTrue(app.buttons[action].isHittable)
            XCTAssertTrue(app.buttons["Cancel"].isHittable)
            capture(app, name: "draft-\(action)-\(orientation.rawValue)")
        }
    }

    @MainActor
    private func rotate(_ app: XCUIApplication, to orientation: UIDeviceOrientation) {
        XCUIDevice.shared.orientation = orientation
        let resized = XCTNSPredicateExpectation(
            predicate: .init { _, _ in
                let frame = app.frame
                return orientation.isLandscape ? frame.width > frame.height : frame.width < frame.height
            },
            object: nil
        )
        wait(for: [resized], timeout: 5)
    }

    @MainActor
    private func launchCollection(route: String) -> XCUIApplication {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = arguments(route: route)
        app.launch()
        return app
    }

    private func arguments(route: String) -> [String] {
        [
            "--stally-preview-scenario", "integration", "--stally-preview-route", route,
            "-com.apple.TipKit.HideAllTips", "1",
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US"
        ]
    }

    @MainActor
    private func capture(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "\(name)-\(app.frame.width)x\(app.frame.height)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
