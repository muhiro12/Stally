@testable import StallyLibrary
import XCTest

@MainActor
final class ItemInsightsCadenceTests: XCTestCase {
    func testWeekdaySummariesAggregateMarksAndActiveDays() throws {
        let context = testContext()
        let weekdayItem = try createTestItem(
            context: context,
            name: "Weekday Coat",
            category: .clothing
        )
        let secondItem = try createTestItem(
            context: context,
            name: "Second Coat",
            category: .clothing
        )

        _ = try markTestItem(
            context: context,
            item: weekdayItem,
            on: localDate(year: 2_026, month: 3, day: 2)
        )
        _ = try markTestItem(
            context: context,
            item: weekdayItem,
            on: localDate(year: 2_026, month: 3, day: 4)
        )
        _ = try markTestItem(
            context: context,
            item: secondItem,
            on: localDate(year: 2_026, month: 3, day: 4)
        )
        _ = try markTestItem(
            context: context,
            item: secondItem,
            on: localDate(year: 2_026, month: 3, day: 7)
        )

        let summaries = ItemInsightsCalculator.weekdaySummaries(
            from: [weekdayItem, secondItem],
            range: .last30Days,
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        let monday = try XCTUnwrap(
            summaries.first { summary in
                summary.weekday == 2
            }
        )
        let wednesday = try XCTUnwrap(
            summaries.first { summary in
                summary.weekday == 4
            }
        )
        let saturday = try XCTUnwrap(
            summaries.first { summary in
                summary.weekday == 7
            }
        )

        XCTAssertEqual(monday.markCount, 1)
        XCTAssertEqual(monday.activeDays, 1)
        XCTAssertEqual(wednesday.markCount, 2)
        XCTAssertEqual(wednesday.activeDays, 1)
        XCTAssertEqual(wednesday.shareOfMarks, 0.5)
        XCTAssertEqual(saturday.markCount, 1)
        XCTAssertEqual(saturday.activeDays, 1)
    }

    func testCadenceSummaryTracksWeeklyConsistencyAndWeekendShare() throws {
        let context = testContext()
        let item = try createTestItem(
            context: context,
            name: "Canvas Tote",
            category: .bags
        )
        let secondItem = try createTestItem(
            context: context,
            name: "Weekend Tote",
            category: .bags
        )

        _ = try markTestItem(
            context: context,
            item: item,
            on: localDate(year: 2_026, month: 3, day: 2)
        )
        _ = try markTestItem(
            context: context,
            item: secondItem,
            on: localDate(year: 2_026, month: 3, day: 4)
        )
        _ = try markTestItem(
            context: context,
            item: secondItem,
            on: localDate(year: 2_026, month: 3, day: 8)
        )

        let summary = ItemInsightsCalculator.cadenceSummary(
            from: [item, secondItem],
            range: .last30Days,
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        XCTAssertEqual(summary.totalWeeks, 6)
        XCTAssertEqual(summary.activeWeeks, 2)
        XCTAssertEqual(summary.averageMarksPerWeek, 0.5, accuracy: 0.001)
        XCTAssertEqual(summary.averageActiveDaysPerWeek, 0.5, accuracy: 0.001)
        XCTAssertEqual(summary.weekdayMarks, 2)
        XCTAssertEqual(summary.weekendMarks, 1)
        XCTAssertEqual(summary.weekendShareOfMarks, 1.0 / 3.0, accuracy: 0.001)
        XCTAssertEqual(summary.consistencyScore, 1.0 / 3.0, accuracy: 0.001)

        let expectedWeekStart = Calendar.current.dateInterval(
            of: .weekOfYear,
            for: localDate(year: 2_026, month: 3, day: 2)
        )?.start
        XCTAssertEqual(summary.busiestWeekStart, expectedWeekStart)
    }

    func testCadenceSummaryCanIncludeArchivedItems() throws {
        let context = testContext()
        let activeItem = try createTestItem(
            context: context,
            name: "Active Notebook",
            category: .notebooks
        )
        let archivedItem = try createTestItem(
            context: context,
            name: "Stored Notebook",
            category: .notebooks
        )

        _ = try markTestItem(
            context: context,
            item: activeItem,
            on: localDate(year: 2_026, month: 3, day: 6)
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

        let activeOnly = ItemInsightsCalculator.cadenceSummary(
            from: [activeItem, archivedItem],
            range: .last30Days,
            includeArchivedItems: false,
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )
        let includingArchived = ItemInsightsCalculator.cadenceSummary(
            from: [activeItem, archivedItem],
            range: .last30Days,
            includeArchivedItems: true,
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        XCTAssertEqual(activeOnly.weekdayMarks + activeOnly.weekendMarks, 1)
        XCTAssertEqual(includingArchived.weekdayMarks + includingArchived.weekendMarks, 2)
    }
}
