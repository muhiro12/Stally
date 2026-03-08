@testable import StallyLibrary
import XCTest

@MainActor
final class ItemInsightsRankingTests: XCTestCase {
    func testTopItemRankingsSortByMarksThenActiveDays() throws {
        let context = testContext()
        let topItem = try createTestItem(
            context: context,
            name: "Black Tee",
            category: .clothing
        )
        let steadyItem = try createTestItem(
            context: context,
            name: "Canvas Tote",
            category: .bags
        )
        let quietItem = try createTestItem(
            context: context,
            name: "Notebook",
            category: .notebooks
        )

        for day in [3, 5, 8] {
            _ = try markTestItem(
                context: context,
                item: topItem,
                on: localDate(year: 2_026, month: 3, day: day)
            )
        }
        for day in [4, 8] {
            _ = try markTestItem(
                context: context,
                item: steadyItem,
                on: localDate(year: 2_026, month: 3, day: day)
            )
        }

        let rankings = ItemInsightsCalculator.topItemRankings(
            from: [quietItem, steadyItem, topItem],
            range: .last30Days,
            limit: 2,
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        XCTAssertEqual(rankings.map(\.itemID), [topItem.id, steadyItem.id])
        XCTAssertEqual(rankings.first?.totalMarksInRange, 3)
        XCTAssertEqual(rankings.last?.totalMarksInRange, 2)
    }

    func testQuietItemRankingsBringUntouchedItemsToTheFront() throws {
        let context = testContext()
        let untouchedItem = try createTestItem(
            context: context,
            name: "Untouched Bag",
            category: .bags
        )
        let oldItem = try createTestItem(
            context: context,
            name: "Old Tee",
            category: .clothing
        )
        let recentItem = try createTestItem(
            context: context,
            name: "Recent Tee",
            category: .clothing
        )

        _ = try markTestItem(
            context: context,
            item: oldItem,
            on: localDate(year: 2_026, month: 3, day: 1)
        )
        _ = try markTestItem(
            context: context,
            item: recentItem,
            on: localDate(year: 2_026, month: 3, day: 8)
        )

        let rankings = ItemInsightsCalculator.quietItemRankings(
            from: [recentItem, untouchedItem, oldItem],
            range: .last30Days,
            limit: 3,
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        XCTAssertEqual(rankings.first?.itemID, untouchedItem.id)
        XCTAssertEqual(rankings.last?.itemID, recentItem.id)
    }

    func testTopItemRankingsCanIncludeArchivedItems() throws {
        let context = testContext()
        let activeItem = try createTestItem(
            context: context,
            name: "Active Coat",
            category: .clothing
        )
        let archivedItem = try createTestItem(
            context: context,
            name: "Archived Shoes",
            category: .shoes
        )

        _ = try markTestItem(
            context: context,
            item: activeItem,
            on: localDate(year: 2_026, month: 3, day: 7)
        )
        _ = try markTestItem(
            context: context,
            item: archivedItem,
            on: localDate(year: 2_026, month: 3, day: 8)
        )
        try archiveTestItem(
            context: context,
            item: archivedItem,
            at: localDate(year: 2_026, month: 3, day: 9)
        )

        let activeOnly = ItemInsightsCalculator.topItemRankings(
            from: [activeItem, archivedItem],
            range: .last30Days,
            includeArchivedItems: false,
            referenceDate: localDate(year: 2_026, month: 3, day: 10)
        )
        let includingArchived = ItemInsightsCalculator.topItemRankings(
            from: [activeItem, archivedItem],
            range: .last30Days,
            includeArchivedItems: true,
            referenceDate: localDate(year: 2_026, month: 3, day: 10)
        )

        XCTAssertEqual(activeOnly.count, 1)
        XCTAssertEqual(includingArchived.count, 2)
        XCTAssertTrue(includingArchived.contains { $0.itemID == archivedItem.id })
    }
}
