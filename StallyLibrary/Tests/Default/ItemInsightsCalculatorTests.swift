@testable import StallyLibrary
import SwiftData
import XCTest

@MainActor
final class ItemInsightsCalculatorTests: XCTestCase {
    private struct ArchiveSummaryFixture {
        let recentArchivedItem: Item
        let olderArchivedItem: Item
        let activeItem: Item
    }

    func testSummaryReturnsTotalLastMarkedDateAndTodayState() throws {
        let context = testContext()
        let item = try createTestItem(
            context: context,
            name: "Crossbody Bag",
            category: .bags
        )

        _ = try markTestItem(
            context: context,
            item: item,
            on: localDate(year: 2_026, month: 3, day: 1)
        )
        _ = try markTestItem(
            context: context,
            item: item,
            on: localDate(year: 2_026, month: 3, day: 8)
        )

        let summary = ItemInsightsCalculator.summary(
            for: item,
            referenceDate: localDate(year: 2_026, month: 3, day: 8, hour: 19)
        )

        XCTAssertEqual(summary.totalMarks, 2)
        XCTAssertTrue(summary.isMarkedToday)
        XCTAssertTrue(
            Calendar.current.isDate(
                summary.lastMarkedAt ?? .distantPast,
                inSameDayAs: localDate(year: 2_026, month: 3, day: 8)
            )
        )
    }

    func testArchiveFilteringSeparatesActiveAndArchivedItems() throws {
        let context = testContext()
        let activeItem = try createTestItem(
            context: context,
            name: "Grey Tee",
            category: .clothing
        )
        let archivedItem = try createTestItem(
            context: context,
            name: "Weekend Tote",
            category: .bags
        )

        try archiveTestItem(
            context: context,
            item: archivedItem,
            at: localDate(year: 2_026, month: 3, day: 8)
        )

        XCTAssertEqual(
            ItemInsightsCalculator
                .activeItems(from: [activeItem, archivedItem])
                .map(\.id),
            [activeItem.id]
        )
        XCTAssertEqual(
            ItemInsightsCalculator
                .archivedItems(from: [activeItem, archivedItem])
                .map(\.id),
            [archivedItem.id]
        )
    }

    func testActiveSummaryCountsMarkedTodayUntouchedItemsAndTotalMarks() throws {
        let context = testContext()
        let markedTodayItem = try createTestItem(
            context: context,
            name: "Black Tee",
            category: .clothing
        )
        let previouslyMarkedItem = try createTestItem(
            context: context,
            name: "Canvas Tote",
            category: .bags
        )
        let untouchedItem = try createTestItem(
            context: context,
            name: "Pocket Notebook",
            category: .notebooks
        )

        _ = try markTestItem(
            context: context,
            item: markedTodayItem,
            on: localDate(year: 2_026, month: 3, day: 8)
        )
        _ = try markTestItem(
            context: context,
            item: previouslyMarkedItem,
            on: localDate(year: 2_026, month: 3, day: 6)
        )
        _ = try markTestItem(
            context: context,
            item: previouslyMarkedItem,
            on: localDate(year: 2_026, month: 3, day: 7)
        )

        let summary = ItemInsightsCalculator.activeSummary(
            from: [markedTodayItem, previouslyMarkedItem, untouchedItem],
            referenceDate: localDate(year: 2_026, month: 3, day: 8, hour: 20)
        )

        XCTAssertEqual(summary.totalItems, 3)
        XCTAssertEqual(summary.markedTodayCount, 1)
        XCTAssertEqual(summary.neverMarkedCount, 1)
        XCTAssertEqual(summary.totalMarks, 3)
    }

    func testArchiveSummaryTracksMarkedItemsAndLatestArchiveDate() throws {
        let context = testContext()
        let fixture = try makeArchiveSummaryFixture(context: context)
        let summary = ItemInsightsCalculator.archiveSummary(
            from: [
                fixture.olderArchivedItem,
                fixture.activeItem,
                fixture.recentArchivedItem
            ]
        )

        XCTAssertEqual(summary.totalItems, 2)
        XCTAssertEqual(summary.itemsWithMarksCount, 2)
        XCTAssertEqual(summary.totalMarks, 3)
        XCTAssertTrue(
            Calendar.current.isDate(
                summary.lastArchivedAt ?? .distantPast,
                inSameDayAs: localDate(year: 2_026, month: 3, day: 8)
            )
        )
    }

    private func makeArchiveSummaryFixture(
        context: ModelContext
    ) throws -> ArchiveSummaryFixture {
        let recentArchivedItem = try createTestItem(
            context: context,
            name: "Recent Coat",
            category: .clothing
        )
        let olderArchivedItem = try createTestItem(
            context: context,
            name: "Old Tote",
            category: .bags
        )
        let activeItem = try createTestItem(
            context: context,
            name: "Active Notebook",
            category: .notebooks
        )

        _ = try markTestItem(
            context: context,
            item: recentArchivedItem,
            on: localDate(year: 2_026, month: 3, day: 4)
        )
        _ = try markTestItem(
            context: context,
            item: olderArchivedItem,
            on: localDate(year: 2_026, month: 3, day: 1)
        )
        _ = try markTestItem(
            context: context,
            item: olderArchivedItem,
            on: localDate(year: 2_026, month: 3, day: 2)
        )
        try archiveTestItem(
            context: context,
            item: olderArchivedItem,
            at: localDate(year: 2_026, month: 3, day: 3)
        )
        try archiveTestItem(
            context: context,
            item: recentArchivedItem,
            at: localDate(year: 2_026, month: 3, day: 8)
        )

        return .init(
            recentArchivedItem: recentArchivedItem,
            olderArchivedItem: olderArchivedItem,
            activeItem: activeItem
        )
    }
}
