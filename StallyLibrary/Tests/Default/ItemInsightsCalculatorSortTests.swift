@testable import StallyLibrary
import XCTest

@MainActor
final class ItemInsightsCalculatorSortTests: XCTestCase {
    func testItemListQuerySortsByRecentlyMarkedWithUnmarkedItemsLast() throws {
        let context = testContext()
        let recentlyMarkedItem = try createTestItem(
            context: context,
            name: "Recent Tote",
            category: .bags
        )
        let olderMarkedItem = try createTestItem(
            context: context,
            name: "Older Tote",
            category: .bags
        )
        let neverMarkedItem = try createTestItem(
            context: context,
            name: "Fresh Tote",
            category: .bags
        )

        _ = try markTestItem(
            context: context,
            item: olderMarkedItem,
            on: localDate(year: 2_026, month: 3, day: 3)
        )
        _ = try markTestItem(
            context: context,
            item: recentlyMarkedItem,
            on: localDate(year: 2_026, month: 3, day: 7)
        )

        let results = ItemInsightsCalculator.items(
            from: [neverMarkedItem, olderMarkedItem, recentlyMarkedItem],
            matching: .init(
                category: .bags,
                sortOption: .recentlyMarked
            ),
            kind: .active,
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        XCTAssertEqual(
            results.map(\.id),
            [recentlyMarkedItem.id, olderMarkedItem.id, neverMarkedItem.id]
        )
    }

    func testItemListQuerySortsByNameCaseInsensitively() throws {
        let context = testContext()
        let zuluItem = try createTestItem(
            context: context,
            name: "Zulu Coat",
            category: .clothing
        )
        let alphaItem = try createTestItem(
            context: context,
            name: "alpha Coat",
            category: .clothing
        )
        let bravoItem = try createTestItem(
            context: context,
            name: "Bravo Coat",
            category: .clothing
        )

        let results = ItemInsightsCalculator.items(
            from: [zuluItem, bravoItem, alphaItem],
            matching: .init(
                category: .clothing,
                sortOption: .name
            ),
            kind: .active,
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        XCTAssertEqual(
            results.map(\.id),
            [alphaItem.id, bravoItem.id, zuluItem.id]
        )
    }
}
