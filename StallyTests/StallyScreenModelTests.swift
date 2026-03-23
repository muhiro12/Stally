import Foundation
@testable import Stally
@testable import StallyLibrary
import XCTest

final class StallyScreenModelTests: XCTestCase {
    func testHomeScreenModelBuildsDisplayedItemsAndUtilityPanels() async throws {
        try await MainActor.run {
            let context = testContext()
            let firstItem = try createTestItem(
                context: context,
                name: "Daily Tote",
                category: .bags,
                createdAt: localDate(year: 2_026, month: 3, day: 1)
            )
            let secondItem = try createTestItem(
                context: context,
                name: "Notebook",
                category: .notebooks,
                createdAt: localDate(year: 2_026, month: 3, day: 2)
            )
            try markTestItem(
                context: context,
                item: firstItem,
                on: localDate(year: 2_026, month: 3, day: 20)
            )

            let snapshot = StallyLibrarySnapshotBuilder.build(
                items: try fetchItems(context: context),
                reviewPreferences: .init()
            )
            let model = StallyHomeScreenModel(snapshot: snapshot)

            model.selectQuickFilter(.withoutHistory)

            XCTAssertEqual(model.displayedItems.map(\.name), [secondItem.name])
            XCTAssertEqual(model.utilityPanels.count, 4)
            XCTAssertEqual(model.homeSummaryMetrics.first?.value, "1")
            XCTAssertEqual(model.totalLibraryMarks, 1)
        }
    }

    func testArchiveScreenModelFiltersArchivedItems() async throws {
        // swiftlint:disable:next closure_body_length
        try await MainActor.run {
            let context = testContext()
            let archivedWithHistory = try createTestItem(
                context: context,
                name: "Film Camera",
                category: .bags
            )
            let archivedWithoutHistory = try createTestItem(
                context: context,
                name: "Spare Scarf",
                category: .clothing
            )
            try markTestItem(
                context: context,
                item: archivedWithHistory,
                on: localDate(year: 2_026, month: 3, day: 10)
            )
            try archiveTestItem(
                context: context,
                item: archivedWithHistory,
                at: localDate(year: 2_026, month: 3, day: 11)
            )
            try archiveTestItem(
                context: context,
                item: archivedWithoutHistory,
                at: localDate(year: 2_026, month: 3, day: 12)
            )

            let snapshot = StallyArchiveSnapshotBuilder.build(
                items: try fetchItems(context: context)
            )
            let model = StallyArchiveScreenModel(snapshot: snapshot)

            model.selectQuickFilter(.withoutHistory)

            XCTAssertEqual(model.displayedItems.map(\.name), [archivedWithoutHistory.name])
            XCTAssertEqual(model.archiveMetrics.first?.value, "2")
        }
    }
    func testReviewScreenModelExposesVisibilityAndSelectionTip() async throws {
        try await MainActor.run {
            let context = testContext()
            _ = try createTestItem(
                context: context,
                name: "Item One",
                category: .other,
                createdAt: localDate(year: 2_026, month: 2, day: 1)
            )
            _ = try createTestItem(
                context: context,
                name: "Item Two",
                category: .other,
                createdAt: localDate(year: 2_026, month: 2, day: 2)
            )

            let snapshot = StallyReviewSnapshotBuilder.build(
                items: try fetchItems(context: context),
                preferences: .init()
            )
            let model = StallyReviewScreenModel(
                snapshot: snapshot,
                showsCompletedSections: false
            )

            XCTAssertTrue(model.shouldShowUntouchedSection)
            XCTAssertEqual(model.selectionTipLane, .untouched)
            XCTAssertEqual(model.summaryMetrics.first?.value, "2")
        }
    }

    func testInsightsScreenModelBuildsMetricsAndChartHelpers() async throws {
        try await MainActor.run {
            let context = testContext()
            let item = try createTestItem(
                context: context,
                name: "Field Notes",
                category: .notebooks
            )
            try markTestItem(
                context: context,
                item: item,
                on: localDate(year: 2_026, month: 3, day: 18)
            )
            try markTestItem(
                context: context,
                item: item,
                on: localDate(year: 2_026, month: 3, day: 19)
            )

            let snapshot = StallyInsightsSnapshotBuilder.build(
                items: try fetchItems(context: context),
                preferences: .init()
            )
            let model = StallyInsightsScreenModel(snapshot: snapshot)

            XCTAssertEqual(model.overviewMetrics.first?.value, "2")
            XCTAssertGreaterThan(model.barHeight(for: snapshot.activityDays[0]), 0)
            XCTAssertTrue(model.shouldShowLabel(for: snapshot.activityDays[0]))
        }
    }

    func testSettingsScreenModelBuildsCardsAndRoutes() async {
        await MainActor.run {
            let model = StallySettingsScreenModel(
                snapshot: StallySettingsSnapshotBuilder.build()
            )

            XCTAssertEqual(model.buildCards.map(\.title), ["Version", "Build"])
            XCTAssertTrue(model.deepLinkRows.contains { $0.route == .backup })
        }
    }
}
