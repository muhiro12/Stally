@testable import StallyLibrary
import XCTest

@MainActor
final class ItemInsightsHealthTests: XCTestCase {
    func testHealthSummaryTracksCoverageAgeAndRecentItems() throws {
        let context = testContext()
        let activeDetailed = try createTestItem(
            context: context,
            name: "Detailed Tee",
            category: .clothing,
            note: "Fits well",
            photoData: Data([1, 2, 3]),
            createdAt: localDate(year: 2_026, month: 2, day: 20)
        )
        let activeMinimal = try createTestItem(
            context: context,
            name: "Quiet Tote",
            category: .bags,
            createdAt: localDate(year: 2_026, month: 3, day: 5)
        )
        let archivedItem = try createTestItem(
            context: context,
            name: "Stored Shoes",
            category: .shoes,
            note: "For travel",
            createdAt: localDate(year: 2_026, month: 1, day: 10)
        )

        _ = try markTestItem(
            context: context,
            item: activeDetailed,
            on: localDate(year: 2_026, month: 3, day: 1)
        )
        _ = try markTestItem(
            context: context,
            item: archivedItem,
            on: localDate(year: 2_026, month: 2, day: 1)
        )
        try archiveTestItem(
            context: context,
            item: archivedItem,
            at: localDate(year: 2_026, month: 3, day: 2)
        )

        let summary = ItemInsightsCalculator.healthSummary(
            from: [activeDetailed, activeMinimal, archivedItem],
            range: .last30Days,
            referenceDate: localDate(year: 2_026, month: 3, day: 10)
        )

        XCTAssertEqual(summary.totalItems, 3)
        XCTAssertEqual(summary.activeItems, 2)
        XCTAssertEqual(summary.archivedItems, 1)
        XCTAssertEqual(summary.itemsWithHistory, 2)
        XCTAssertEqual(summary.itemsWithNotes, 2)
        XCTAssertEqual(summary.itemsWithPhotos, 1)
        XCTAssertEqual(summary.historyCoverage, 2.0 / 3.0, accuracy: 0.001)
        XCTAssertEqual(summary.noteCoverage, 2.0 / 3.0, accuracy: 0.001)
        XCTAssertEqual(summary.photoCoverage, 1.0 / 3.0, accuracy: 0.001)
        XCTAssertEqual(summary.archivedShare, 1.0 / 3.0, accuracy: 0.001)
        XCTAssertEqual(summary.averageItemAgeDays, 82.0 / 3.0, accuracy: 0.001)
        XCTAssertEqual(summary.recentlyAddedCount, 2)
    }

    func testHealthSummaryCanExcludeArchivedItems() throws {
        let context = testContext()
        let activeItem = try createTestItem(
            context: context,
            name: "Active Notebook",
            category: .notebooks,
            createdAt: localDate(year: 2_026, month: 3, day: 1)
        )
        let archivedItem = try createTestItem(
            context: context,
            name: "Archived Notebook",
            category: .notebooks,
            createdAt: localDate(year: 2_026, month: 3, day: 1)
        )

        try archiveTestItem(
            context: context,
            item: archivedItem,
            at: localDate(year: 2_026, month: 3, day: 5)
        )

        let activeOnly = ItemInsightsCalculator.healthSummary(
            from: [activeItem, archivedItem],
            range: .last30Days,
            includeArchivedItems: false,
            referenceDate: localDate(year: 2_026, month: 3, day: 10)
        )

        XCTAssertEqual(activeOnly.totalItems, 1)
        XCTAssertEqual(activeOnly.archivedItems, 0)
        XCTAssertEqual(activeOnly.activeItems, 1)
    }
}
