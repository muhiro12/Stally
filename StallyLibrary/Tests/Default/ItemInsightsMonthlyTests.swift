@testable import StallyLibrary
import XCTest

@MainActor
final class ItemInsightsMonthlyTests: XCTestCase {
    func testMonthlySummariesReturnContiguousMonthsAcrossTheWindow() throws {
        let context = testContext()
        let januaryItem = try createTestItem(
            context: context,
            name: "January Tee",
            category: .clothing,
            createdAt: localDate(year: 2_026, month: 1, day: 5)
        )
        let marchItem = try createTestItem(
            context: context,
            name: "March Tote",
            category: .bags,
            createdAt: localDate(year: 2_026, month: 3, day: 1)
        )

        _ = try markTestItem(
            context: context,
            item: januaryItem,
            on: localDate(year: 2_026, month: 1, day: 15)
        )
        _ = try markTestItem(
            context: context,
            item: januaryItem,
            on: localDate(year: 2_026, month: 3, day: 1)
        )
        _ = try markTestItem(
            context: context,
            item: marchItem,
            on: localDate(year: 2_026, month: 3, day: 5)
        )

        let summaries = ItemInsightsCalculator.monthlySummaries(
            from: [januaryItem, marchItem],
            range: .allTime,
            referenceDate: localDate(year: 2_026, month: 3, day: 31)
        )

        XCTAssertEqual(summaries.count, 3)
        XCTAssertEqual(
            summaries.map(\.monthStart),
            [
                localDate(year: 2_026, month: 1, day: 1, hour: 0),
                localDate(year: 2_026, month: 2, day: 1, hour: 0),
                localDate(year: 2_026, month: 3, day: 1, hour: 0)
            ]
        )
        XCTAssertEqual(summaries[0].markCount, 1)
        XCTAssertEqual(summaries[1].markCount, 0)
        XCTAssertEqual(summaries[1].activeDays, 0)
        XCTAssertEqual(summaries[2].markCount, 2)
        XCTAssertEqual(summaries[2].uniqueItems, 2)
        XCTAssertEqual(summaries[2].uniqueCategories, 2)
        XCTAssertEqual(summaries[2].averageMarksPerActiveDay, 1.0, accuracy: 0.001)
    }

    func testMonthlySummariesCanExcludeArchivedItems() throws {
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

        _ = try markTestItem(
            context: context,
            item: activeItem,
            on: localDate(year: 2_026, month: 3, day: 3)
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

        let activeOnly = ItemInsightsCalculator.monthlySummaries(
            from: [activeItem, archivedItem],
            range: .last30Days,
            includeArchivedItems: false,
            referenceDate: localDate(year: 2_026, month: 3, day: 31)
        )
        let includingArchived = ItemInsightsCalculator.monthlySummaries(
            from: [activeItem, archivedItem],
            range: .last30Days,
            includeArchivedItems: true,
            referenceDate: localDate(year: 2_026, month: 3, day: 31)
        )

        XCTAssertEqual(activeOnly.last?.markCount, 1)
        XCTAssertEqual(includingArchived.last?.markCount, 2)
    }
}
