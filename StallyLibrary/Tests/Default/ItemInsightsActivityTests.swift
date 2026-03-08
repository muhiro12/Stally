@testable import StallyLibrary
import SwiftData
import XCTest

@MainActor
final class ItemInsightsActivityTests: XCTestCase {
    func testActivityDaysBuildFixedRangeTimelineForActiveItems() throws {
        let context = testContext()
        let activeItem = try createTestItem(
            context: context,
            name: "Daily Tee",
            category: .clothing,
            createdAt: localDate(year: 2_026, month: 2, day: 1)
        )
        let archivedItem = try createTestItem(
            context: context,
            name: "Stored Tote",
            category: .bags,
            createdAt: localDate(year: 2_026, month: 2, day: 1)
        )

        _ = try markTestItem(
            context: context,
            item: activeItem,
            on: localDate(year: 2_026, month: 3, day: 6)
        )
        _ = try markTestItem(
            context: context,
            item: activeItem,
            on: localDate(year: 2_026, month: 3, day: 8)
        )
        _ = try markTestItem(
            context: context,
            item: archivedItem,
            on: localDate(year: 2_026, month: 3, day: 7)
        )
        try archiveTestItem(
            context: context,
            item: archivedItem,
            at: localDate(year: 2_026, month: 3, day: 8)
        )

        let activityDays = ItemInsightsCalculator.activityDays(
            from: [activeItem, archivedItem],
            range: .last30Days,
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        XCTAssertEqual(activityDays.count, 30)
        XCTAssertTrue(
            Calendar.current.isDate(
                activityDays.first?.date ?? .distantPast,
                inSameDayAs: localDate(year: 2_026, month: 2, day: 7)
            )
        )
        XCTAssertTrue(
            Calendar.current.isDate(
                activityDays.last?.date ?? .distantPast,
                inSameDayAs: localDate(year: 2_026, month: 3, day: 8)
            )
        )
        XCTAssertEqual(
            activityDays.filter(\.isActive).map(\.markCount),
            [1, 1]
        )
    }

    func testActivitySummaryOptionallyIncludesArchivedItems() throws {
        let context = testContext()
        let activeItem = try createTestItem(
            context: context,
            name: "Active Coat",
            category: .clothing
        )
        let archivedItem = try createTestItem(
            context: context,
            name: "Archived Bag",
            category: .bags
        )

        _ = try markTestItem(
            context: context,
            item: activeItem,
            on: localDate(year: 2_026, month: 3, day: 2)
        )
        _ = try markTestItem(
            context: context,
            item: archivedItem,
            on: localDate(year: 2_026, month: 3, day: 4)
        )
        try archiveTestItem(
            context: context,
            item: archivedItem,
            at: localDate(year: 2_026, month: 3, day: 5)
        )

        let activeOnlySummary = ItemInsightsCalculator.activitySummary(
            from: [activeItem, archivedItem],
            range: .last30Days,
            includeArchivedItems: false,
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )
        let combinedSummary = ItemInsightsCalculator.activitySummary(
            from: [activeItem, archivedItem],
            range: .last30Days,
            includeArchivedItems: true,
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        XCTAssertEqual(activeOnlySummary.totalMarks, 1)
        XCTAssertEqual(activeOnlySummary.uniqueMarkedItems, 1)
        XCTAssertEqual(combinedSummary.totalMarks, 2)
        XCTAssertEqual(combinedSummary.uniqueMarkedItems, 2)
        XCTAssertEqual(combinedSummary.uniqueMarkedCategories, 2)
    }

    func testAllTimeSummaryStartsAtEarliestKnownCollectionDay() throws {
        let context = testContext()
        let item = try createTestItem(
            context: context,
            name: "Notebook",
            category: .notebooks,
            createdAt: localDate(year: 2_026, month: 1, day: 15)
        )
        let secondItem = try createTestItem(
            context: context,
            name: "Canvas Tote",
            category: .bags,
            createdAt: localDate(year: 2_026, month: 1, day: 20)
        )

        _ = try markTestItem(
            context: context,
            item: item,
            on: localDate(year: 2_026, month: 2, day: 3)
        )
        _ = try markTestItem(
            context: context,
            item: secondItem,
            on: localDate(year: 2_026, month: 2, day: 3)
        )
        _ = try markTestItem(
            context: context,
            item: item,
            on: localDate(year: 2_026, month: 3, day: 8)
        )

        let activityDays = ItemInsightsCalculator.activityDays(
            from: [item, secondItem],
            range: .allTime,
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )
        let summary = ItemInsightsCalculator.activitySummary(
            from: [item, secondItem],
            range: .allTime,
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        XCTAssertTrue(
            Calendar.current.isDate(
                activityDays.first?.date ?? .distantPast,
                inSameDayAs: localDate(year: 2_026, month: 1, day: 15)
            )
        )
        XCTAssertEqual(summary.totalMarks, 3)
        XCTAssertEqual(summary.activeDays, 2)
        XCTAssertEqual(summary.busiestDay?.markCount, 2)
        XCTAssertTrue(
            Calendar.current.isDate(
                summary.busiestDay?.date ?? .distantPast,
                inSameDayAs: localDate(year: 2_026, month: 2, day: 3)
            )
        )
    }
}
