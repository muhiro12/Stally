@testable import StallyLibrary
import XCTest

@MainActor
final class ItemInsightsStreakTests: XCTestCase {
    func testStreakSummaryTracksCurrentAndBestStreaks() throws {
        let context = testContext()
        let item = try createTestItem(
            context: context,
            name: "Frequent Tee",
            category: .clothing
        )

        for day in [4, 5, 6, 8, 9, 10] {
            _ = try markTestItem(
                context: context,
                item: item,
                on: localDate(year: 2_026, month: 3, day: day)
            )
        }

        let summary = ItemInsightsCalculator.streakSummary(
            from: [item],
            range: .last30Days,
            referenceDate: localDate(year: 2_026, month: 3, day: 10)
        )

        XCTAssertEqual(summary.currentStreakDays, 3)
        XCTAssertEqual(summary.bestStreakDays, 3)
        XCTAssertEqual(summary.longestIdleGapDays, 1)
        XCTAssertEqual(summary.daysSinceLastActive, 0)
    }

    func testStreakSummaryResetsCurrentStreakWhenReferenceDayIsInactive() throws {
        let context = testContext()
        let item = try createTestItem(
            context: context,
            name: "Weekend Tote",
            category: .bags
        )

        for day in [1, 2, 3, 7] {
            _ = try markTestItem(
                context: context,
                item: item,
                on: localDate(year: 2_026, month: 3, day: day)
            )
        }

        let summary = ItemInsightsCalculator.streakSummary(
            from: [item],
            range: .last30Days,
            referenceDate: localDate(year: 2_026, month: 3, day: 10)
        )

        XCTAssertEqual(summary.currentStreakDays, 0)
        XCTAssertEqual(summary.bestStreakDays, 3)
        XCTAssertEqual(summary.longestIdleGapDays, 3)
        XCTAssertEqual(summary.daysSinceLastActive, 3)
    }

    func testStreakSummaryReturnsZeroesForAnInactiveRange() throws {
        let context = testContext()
        let item = try createTestItem(
            context: context,
            name: "Quiet Notebook",
            category: .notebooks,
            createdAt: localDate(year: 2_026, month: 1, day: 1)
        )

        let summary = ItemInsightsCalculator.streakSummary(
            from: [item],
            range: .last30Days,
            referenceDate: localDate(year: 2_026, month: 3, day: 10)
        )

        XCTAssertEqual(summary.currentStreakDays, 0)
        XCTAssertEqual(summary.bestStreakDays, 0)
        XCTAssertEqual(summary.longestIdleGapDays, 0)
        XCTAssertNil(summary.lastActiveDate)
        XCTAssertNil(summary.daysSinceLastActive)
    }
}
