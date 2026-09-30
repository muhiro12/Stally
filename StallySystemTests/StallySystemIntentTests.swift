import AppIntentsTesting
import XCTest

/// Exercises the installed app through the same pipeline used by system actions.
final class StallySystemIntentTests: XCTestCase {
    private let definitions = IntentDefinitions(bundleIdentifier: "com.muhiro12.Stally")

    @MainActor
    func testNonMarkTimeJourneyPreservesPrecisionAndIdentity() async throws {
        let app = launchSyntheticCollection()
        defer { app.terminate() }

        let create = definitions.intents["CreateStallyItemIntent"].makeIntent(
            name: "System Home",
            recordsMarks: false,
            start: "1998"
        )
        let created = try await create.run()
        let item: AnyAppEntity = try created.value
        let start: String = try item.start
        let recordsMarks: Bool = try item.recordsMarks
        let category: AnyAppEnum = try item.category
        XCTAssertEqual(start, "1998")
        XCTAssertFalse(recordsMarks)
        XCTAssertEqual(category.rawValue, "other")

        let before = try await timeReport(for: item)
        XCTAssertTrue(before.contains("1998"))
        XCTAssertFalse(before.contains("January"))
        await assertRejected("MarkStallyItemTodayIntent", item: item)

        try await assertChanged("ArchiveStallyItemIntent", item: item, expected: true)
        try await assertChanged("ArchiveStallyItemIntent", item: item, expected: false)
        let archived = try await resolved(item)
        XCTAssertTrue(try archived.isArchived)
        XCTAssertEqual(archived.identifier.instanceIdentifier, item.identifier.instanceIdentifier)
        let archivedReport = try await timeReport(for: archived)
        XCTAssertTrue(archivedReport.contains(before))
        XCTAssertTrue(archivedReport.contains("Elapsed time continues"))
        await assertRejected("MarkStallyItemTodayIntent", item: archived)

        try await assertChanged("MoveStallyItemBackToLibraryIntent", item: archived, expected: true)
        try await assertChanged("MoveStallyItemBackToLibraryIntent", item: archived, expected: false)
        let restored = try await resolved(item)
        XCTAssertFalse(try restored.isArchived)
        let restoredReport = try await timeReport(for: restored)
        XCTAssertEqual(restoredReport, before)

        try await definitions.intents["OpenStallyItemEntityIntent"].makeIntent(target: restored).run()
        XCTAssertTrue(app.navigationBars["System Home"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testMarkAndUndoAreIdempotentAndRejectArchivedItems() async throws {
        let app = launchSyntheticCollection()
        defer { app.terminate() }
        let create = definitions.intents["CreateStallyItemIntent"].makeIntent(
            name: "System Tote",
            category: definitions.enums["StallyItemCategoryIntentValue"].makeCase("bags")
        )
        let created = try await create.run()
        let item: AnyAppEntity = try created.value
        XCTAssertTrue(try item.recordsMarks)
        let start: String? = try item.start
        XCTAssertNil(start)
        try await assertChanged("MarkStallyItemTodayIntent", item: item, expected: true)
        try await assertChanged("MarkStallyItemTodayIntent", item: item, expected: false)
        try await assertChanged("UndoStallyItemTodayIntent", item: item, expected: true)
        try await assertChanged("UndoStallyItemTodayIntent", item: item, expected: false)
        try await assertChanged("ArchiveStallyItemIntent", item: item, expected: true)
        await assertRejected("MarkStallyItemTodayIntent", item: item)
        await assertRejected("UndoStallyItemTodayIntent", item: item)
        let matches = try await definitions.entities["StallyItemEntity"].entities(matching: "System Tote")
        XCTAssertEqual(matches.count, 1)
        XCTAssertTrue(try XCTUnwrap(matches.first).isArchived)
    }

    @MainActor
    func testPartialStartsAndInvalidInputUseTheRealResolutionPipeline() async throws {
        let app = launchSyntheticCollection()
        defer { app.terminate() }
        for start in ["2000-02", "2000-02-29"] {
            let create = definitions.intents["CreateStallyItemIntent"].makeIntent(
                name: "System \(start)",
                recordsMarks: false,
                start: start
            )
            let created = try await create.run()
            let actual: String = try created.value.start
            XCTAssertEqual(actual, start)
        }
        for start in ["2000-02-30", "2000-2", "9999"] {
            do {
                let create = definitions.intents["CreateStallyItemIntent"].makeIntent(
                    name: "Rejected \(start)",
                    start: start
                )
                try await create.run()
                XCTFail("Expected invalid or future start to fail")
            } catch {
                let matches = try await definitions.entities["StallyItemEntity"].entities(matching: "Rejected")
                XCTAssertTrue(matches.isEmpty)
            }
        }
        let missing = definitions.entities["StallyItemEntity"].makeReference(
            identifier: "00000000-0000-0000-0000-000000000013"
        )
        let unresolved = try await definitions.entities["StallyItemEntity"].entities(
            identifiers: [missing.identifier.instanceIdentifier]
        )
        XCTAssertTrue(unresolved.isEmpty)
        await assertRejected("CheckStallyTimeTogetherIntent", item: missing)
    }

    @MainActor
    func testOnscreenAnnotationsDisambiguateEqualNamesAndReflectArchive() async throws {
        let app = launchSyntheticCollection()
        defer { app.terminate() }
        let create = definitions.intents["CreateStallyItemIntent"]
        let firstResult = try await create.makeIntent(name: "Same System Name").run()
        let secondResult = try await create.makeIntent(
            name: "Same System Name", recordsMarks: false, start: "2000-02"
        )
        .run()
        let first: AnyAppEntity = try firstResult.value
        let second: AnyAppEntity = try secondResult.value
        XCTAssertNotEqual(first.identifier.instanceIdentifier, second.identifier.instanceIdentifier)
        XCTAssertTrue(app.staticTexts["Same System Name"].firstMatch.waitForExistence(timeout: 5))
        let entity = definitions.entities["StallyItemEntity"]
        let rows = try await entity.viewAnnotations()
        let visibleIDs = Set(rows.map(\.entity.identifier.instanceIdentifier))
        XCTAssertTrue(visibleIDs.contains(first.identifier.instanceIdentifier))
        XCTAssertTrue(visibleIDs.contains(second.identifier.instanceIdentifier))

        try await definitions.intents["OpenStallyItemEntityIntent"].makeIntent(target: second).run()
        XCTAssertTrue(app.navigationBars["Same System Name"].waitForExistence(timeout: 5))
        let detail = try await entity.viewAnnotations()
        let detailIDs = Set(detail.map(\.entity.identifier.instanceIdentifier))
        XCTAssertTrue(detailIDs.contains(second.identifier.instanceIdentifier))
        XCTAssertFalse(detailIDs.contains(first.identifier.instanceIdentifier))
        try await assertChanged("ArchiveStallyItemIntent", item: second, expected: true)
        let archived = try await entity.viewAnnotations()
        let annotation = try XCTUnwrap(archived.first { entry in
            entry.entity.identifier.instanceIdentifier == second.identifier.instanceIdentifier
        })
        let isArchived: Bool = try annotation.entity.isArchived
        XCTAssertTrue(isArchived)
    }

    @MainActor
    private func launchSyntheticCollection() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "--stally-preview-scenario", "empty", "--stally-preview-route", "library",
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US"
        ]
        app.launch()
        return app
    }

    private func timeReport(for item: AnyAppEntity) async throws -> String {
        let result = try await definitions.intents["CheckStallyTimeTogetherIntent"].makeIntent(item: item).run()
        return try result.value
    }

    private func resolved(_ item: AnyAppEntity) async throws -> AnyAppEntity {
        let matches = try await definitions.entities["StallyItemEntity"].entities(
            identifiers: [item.identifier.instanceIdentifier]
        )
        return try XCTUnwrap(matches.first)
    }

    private func assertChanged(_ name: String, item: AnyAppEntity, expected: Bool) async throws {
        let result = try await definitions.intents[name].makeIntent(item: item).run()
        let changed: Bool = try result.value
        XCTAssertEqual(changed, expected)
    }

    private func assertRejected(_ name: String, item: AnyAppEntity) async {
        do {
            try await definitions.intents[name].makeIntent(item: item).run()
            XCTFail("Expected \(name) to reject this Item")
        } catch {
            XCTAssertFalse(String(describing: error).isEmpty)
        }
    }
}
