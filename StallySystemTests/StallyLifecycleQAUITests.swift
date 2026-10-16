import UIKit
import XCTest

/// Qualifies lifecycle and large-text journeys using disposable in-memory data.
final class StallyLifecycleQAUITests: XCTestCase {
    private static let maximumScrollAttempts = 20

    @MainActor
    func testSafariReturnKeepsTheSyntheticCollection() {
        let app = launch(route: "addItem")
        defer {
            app.terminate()
        }
        XCTAssertTrue(app.navigationBars["Add Item"].waitForExistence(timeout: 10))
        app.textFields["Name"].tap()
        app.textFields["Name"].typeText("Safari Return Sentinel")
        app.buttons["Add"].tap()
        XCTAssertTrue(app.staticTexts["Safari Return Sentinel"].waitForExistence(timeout: 5))
        app.buttons["Settings"].firstMatch.tap()
        let support = app.links["Support"].firstMatch
        scrollTo(support, in: app)
        support.tap()
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        defer {
            safari.terminate()
        }
        XCTAssertTrue(safari.wait(for: .runningForeground, timeout: 15))
        // Windowed apps can remain foreground while another app is active.
        let retainedStates: [XCUIApplication.State] = [
            .runningForeground, .runningBackground, .runningBackgroundSuspended
        ]
        XCTAssertTrue(retainedStates.contains(app.state))
        app.activate()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 10))
        capture("safari-return-settings")
        let bar = app.navigationBars["Settings"]
        bar.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).press(
            forDuration: 0.1,
            thenDragTo: app.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.95))
        )
        XCTAssertTrue(app.navigationBars["Library"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Safari Return Sentinel"].waitForExistence(timeout: 5))
        capture("safari-return-retained-collection")
    }

    @MainActor
    func testSignificantTimeChangeRefreshesTheRetainedDetail() {
        let app = launch(route: "itemDetail", extra: [
            "--stally-preview-advance-day-after", "45", "--stally-preview-send-time-change"
        ])
        defer {
            app.terminate()
        }
        let undo = app.buttons["Undo Today's Mark"].firstMatch
        XCTAssertTrue(undo.waitForExistence(timeout: 10))
        capture("before-injected-midnight")
        let mark = app.buttons["Mark Today"].firstMatch
        XCTAssertTrue(mark.waitForExistence(timeout: 75))
        XCTAssertFalse(undo.exists)
        XCTAssertTrue(mark.isHittable)
        capture("after-time-change-notification")
        mark.tap()
        XCTAssertTrue(undo.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Marked Today"].firstMatch.exists)
        capture("mark-uses-the-advanced-action-date")
    }

    @MainActor
    func testForegroundRefreshesArchivedElapsedTime() async throws {
        let app = launch(route: "archive", extra: ["--stally-preview-advance-day-after", "45"])
        defer {
            app.terminate()
        }
        let plant = app.staticTexts["Archived Plant"].firstMatch
        XCTAssertTrue(plant.waitForExistence(timeout: 10))
        scrollTo(plant, in: app)
        plant.tap()
        XCTAssertTrue(app.staticTexts["Elapsed Time, 2,208 days"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Mark Today"].exists)
        capture("archived-before-background")
        XCUIDevice.shared.press(.home)
        XCTAssertTrue(
            app.wait(for: .runningBackground, timeout: 5)
                || app.wait(for: .runningBackgroundSuspended, timeout: 5)
        )
        try await Task.sleep(for: .seconds(50))
        assertRetainedInBackground(app)
        app.activate()
        XCTAssertTrue(app.navigationBars["Archived Plant"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Elapsed Time, 2,209 days"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Mark Today"].exists)
        XCTAssertFalse(app.buttons["Undo Today's Mark"].exists)
        capture("archived-after-foreground-day-change")
    }

    @MainActor
    func testMaximumTypeMajorScreens() {
        let app = launch(route: "library", maximumType: true)
        defer {
            app.terminate()
        }
        XCTAssertTrue(app.navigationBars["Library"].waitForExistence(timeout: 10))
        capture("maximum-type-library")
        let home = app.staticTexts["Home"].firstMatch
        scrollTo(home, in: app)
        home.tap()
        XCTAssertTrue(app.navigationBars["Home"].waitForExistence(timeout: 5))
        scrollTo(app.buttons["Share Time Together"].firstMatch, in: app)
        XCTAssertFalse(app.buttons["Mark Today"].exists)
        capture("maximum-type-non-mark-detail")
        app.buttons["Archive"].firstMatch.tap()
        let plant = app.staticTexts["Archived Plant"].firstMatch
        scrollTo(plant, in: app)
        plant.tap()
        XCTAssertTrue(app.navigationBars["Archived Plant"].waitForExistence(timeout: 5))
        capture("maximum-type-archive-detail")
        verifyReflectionAndExport(in: app)
    }

    @MainActor
    func testMaximumTypeJapaneseCreationForm() {
        let app = launch(route: "addItem", maximumType: true, japanese: true)
        defer {
            app.terminate()
        }
        XCTAssertTrue(app.navigationBars["アイテムを追加"].waitForExistence(timeout: 10))
        app.textFields["名前"].tap()
        app.textFields["名前"].typeText("大きい文字で入力した合成データの名前")
        XCTAssertTrue(app.buttons["追加"].isEnabled)
        XCTAssertTrue(app.buttons["追加"].isHittable)
        XCTAssertTrue(app.buttons["キャンセル"].isHittable)
        capture("maximum-type-japanese-creation")
        app.buttons["キャンセル"].tap()
        XCTAssertFalse(app.staticTexts["大きい文字で入力した合成データの名前"].exists)
    }

    @MainActor
    func testMaximumTypeHistoryControls() {
        let app = launch(route: "itemDetail", maximumType: true)
        defer {
            app.terminate()
        }
        XCTAssertTrue(app.navigationBars["Black Wool Coat"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Undo Today's Mark"].firstMatch.isHittable)
        let history = app.buttons["Adjust History"].firstMatch
        scrollTo(history, in: app, above: app.buttons["Undo Today's Mark"].firstMatch)
        capture("maximum-type-readable-history-grid")
        history.tap()
        XCTAssertTrue(app.navigationBars["Adjust History"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.datePickers.firstMatch.exists)
        let remove = app.buttons["Remove Mark"].firstMatch
        scrollTo(remove, in: app)
        XCTAssertTrue(remove.isEnabled)
        XCTAssertTrue(app.buttons["Done"].isHittable)
        capture("maximum-type-history-controls")
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["Undo Today's Mark"].firstMatch.waitForExistence(timeout: 5))
    }
}

private extension StallyLifecycleQAUITests {
    @MainActor
    func assertRetainedInBackground(_ app: XCUIApplication) {
        let retainedStates: [XCUIApplication.State] = [.runningBackground, .runningBackgroundSuspended]
        XCTAssertTrue(retainedStates.contains(app.state))
    }

    @MainActor
    func verifyReflectionAndExport(in app: XCUIApplication) {
        app.buttons["Review"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Review"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Home"].exists)
        capture("maximum-type-review")
        app.buttons["Insights"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Insights"].waitForExistence(timeout: 5))
        capture("maximum-type-insights")
        app.buttons["Settings"].firstMatch.tap()
        let transfer = app.buttons["Import & Export"].firstMatch
        scrollTo(transfer, in: app)
        transfer.tap()
        let export = app.buttons["Export Data"].firstMatch
        scrollTo(export, in: app)
        export.tap()
        XCTAssertTrue(app.navigationBars["Export Data"].waitForExistence(timeout: 5))
        scrollTo(app.buttons["Save to Files"].firstMatch, in: app)
        XCTAssertTrue(app.buttons["Share Data"].isHittable)
        XCTAssertTrue(app.buttons["Done"].isHittable)
        capture("maximum-type-export")
    }

    @MainActor
    func launch(
        route: String,
        maximumType: Bool = false,
        japanese: Bool = false,
        extra: [String] = []
    ) -> XCUIApplication {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = [
            "--stally-preview-scenario", "integration", "--stally-preview-route", route,
            "-com.apple.TipKit.HideAllTips", "1",
            "-AppleLanguages", japanese ? "(ja)" : "(en)", "-AppleLocale", japanese ? "ja_JP" : "en_US"
        ] + extra
        if maximumType {
            app.launchArguments += [
                "--stally-preview-text-size", "accessibility5",
                "-UIPreferredContentSizeCategoryName", UIContentSizeCategory.accessibilityExtraExtraExtraLarge.rawValue
            ]
        }
        app.launch()
        return app
    }

    @MainActor
    func scrollTo(_ element: XCUIElement, in app: XCUIApplication, above fixedAction: XCUIElement? = nil) {
        // Begin inside sheets and above the fixed, large-text action bar.
        let start = app.coordinate(withNormalizedOffset: .init(dx: 0.4, dy: 0.5))
        let end = app.coordinate(withNormalizedOffset: .init(dx: 0.4, dy: 0.15))
        let maximumY = fixedAction?.frame.minY ?? app.frame.maxY
        for _ in 0..<Self.maximumScrollAttempts {
            if element.exists, element.isHittable,
               element.frame.maxY < maximumY {
                return
            }
            start.press(forDuration: 0.1, thenDragTo: end)
        }
        XCTAssertTrue(element.isHittable)
    }

    @MainActor
    func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
