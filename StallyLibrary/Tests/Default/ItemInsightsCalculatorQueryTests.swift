@testable import StallyLibrary
import SwiftData
import XCTest

@MainActor
final class ItemInsightsCalculatorQueryTests: XCTestCase {
    private struct MostMarkedQueryFixture {
        let searchedItem: Item
        let excludedItem: Item
        let otherCategoryItem: Item
    }

    func testItemListQueryFiltersSearchAndCategoryThenSortsByMostMarked() throws {
        let context = testContext()
        let fixture = try makeMostMarkedQueryFixture(context: context)
        let results = ItemInsightsCalculator.items(
            from: [
                fixture.otherCategoryItem,
                fixture.excludedItem,
                fixture.searchedItem
            ],
            matching: .init(
                searchText: "office",
                category: .bags,
                sortOption: .mostMarked
            ),
            kind: .active,
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        XCTAssertEqual(results.map(\.id), [fixture.searchedItem.id])
    }

    func testItemListQueryPreservesArchivedDefaultOrder() throws {
        let context = testContext()
        let earlierArchivedItem = try createTestItem(
            context: context,
            name: "Old Coat",
            category: .clothing,
            createdAt: localDate(year: 2_026, month: 2, day: 1)
        )
        let laterArchivedItem = try createTestItem(
            context: context,
            name: "Recent Coat",
            category: .clothing,
            createdAt: localDate(year: 2_026, month: 2, day: 2)
        )

        try archiveTestItem(
            context: context,
            item: earlierArchivedItem,
            at: localDate(year: 2_026, month: 3, day: 4)
        )
        try archiveTestItem(
            context: context,
            item: laterArchivedItem,
            at: localDate(year: 2_026, month: 3, day: 8)
        )

        let results = ItemInsightsCalculator.items(
            from: [earlierArchivedItem, laterArchivedItem],
            matching: .init(
                category: .clothing,
                sortOption: .defaultOrder
            ),
            kind: .archived,
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        XCTAssertEqual(
            results.map(\.id),
            [laterArchivedItem.id, earlierArchivedItem.id]
        )
    }

    func testItemListQueryQuickFilterSeparatesMarkedAndOpenItemsForReferenceDay() throws {
        let context = testContext()
        let markedTodayItem = try createTestItem(
            context: context,
            name: "Marked Tee",
            category: .clothing
        )
        let openTodayItem = try createTestItem(
            context: context,
            name: "Open Tee",
            category: .clothing
        )

        _ = try markTestItem(
            context: context,
            item: markedTodayItem,
            on: localDate(year: 2_026, month: 3, day: 8)
        )
        _ = try markTestItem(
            context: context,
            item: openTodayItem,
            on: localDate(year: 2_026, month: 3, day: 6)
        )

        let markedResults = ItemInsightsCalculator.items(
            from: [openTodayItem, markedTodayItem],
            matching: .init(
                quickFilter: .markedOnReferenceDay
            ),
            kind: .active,
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )
        let openResults = ItemInsightsCalculator.items(
            from: [openTodayItem, markedTodayItem],
            matching: .init(
                quickFilter: .unmarkedOnReferenceDay
            ),
            kind: .active,
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        XCTAssertEqual(markedResults.map(\.id), [markedTodayItem.id])
        XCTAssertEqual(openResults.map(\.id), [openTodayItem.id])
    }

    func testItemListQueryQuickFilterSeparatesItemsWithAndWithoutHistory() throws {
        let context = testContext()
        let withHistoryItem = try createTestItem(
            context: context,
            name: "History Tote",
            category: .bags
        )
        let withoutHistoryItem = try createTestItem(
            context: context,
            name: "Fresh Tote",
            category: .bags
        )
        let archivedItem = try createTestItem(
            context: context,
            name: "Archived Tote",
            category: .bags
        )

        _ = try markTestItem(
            context: context,
            item: withHistoryItem,
            on: localDate(year: 2_026, month: 3, day: 5)
        )
        _ = try markTestItem(
            context: context,
            item: archivedItem,
            on: localDate(year: 2_026, month: 3, day: 2)
        )
        try archiveTestItem(
            context: context,
            item: archivedItem,
            at: localDate(year: 2_026, month: 3, day: 6)
        )

        let activeWithoutHistory = ItemInsightsCalculator.items(
            from: [withHistoryItem, withoutHistoryItem, archivedItem],
            matching: .init(
                quickFilter: .withoutHistory
            ),
            kind: .active,
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )
        let archivedWithHistory = ItemInsightsCalculator.items(
            from: [withHistoryItem, withoutHistoryItem, archivedItem],
            matching: .init(
                quickFilter: .withHistory
            ),
            kind: .archived,
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        XCTAssertEqual(activeWithoutHistory.map(\.id), [withoutHistoryItem.id])
        XCTAssertEqual(archivedWithHistory.map(\.id), [archivedItem.id])
    }

    private func makeMostMarkedQueryFixture(
        context: ModelContext
    ) throws -> MostMarkedQueryFixture {
        let searchedItem = try createTestItem(
            context: context,
            name: "Office Tote",
            category: .bags,
            note: "Carries my notebook.",
            createdAt: localDate(year: 2_026, month: 3, day: 1)
        )
        let excludedItem = try createTestItem(
            context: context,
            name: "Weekend Tote",
            category: .bags,
            note: "For short trips.",
            createdAt: localDate(year: 2_026, month: 3, day: 2)
        )
        let otherCategoryItem = try createTestItem(
            context: context,
            name: "Daily Notebook",
            category: .notebooks,
            note: "Office notes.",
            createdAt: localDate(year: 2_026, month: 3, day: 3)
        )

        _ = try markTestItem(
            context: context,
            item: searchedItem,
            on: localDate(year: 2_026, month: 3, day: 4)
        )
        _ = try markTestItem(
            context: context,
            item: searchedItem,
            on: localDate(year: 2_026, month: 3, day: 6)
        )
        _ = try markTestItem(
            context: context,
            item: excludedItem,
            on: localDate(year: 2_026, month: 3, day: 5)
        )
        _ = try markTestItem(
            context: context,
            item: otherCategoryItem,
            on: localDate(year: 2_026, month: 3, day: 7)
        )

        return .init(
            searchedItem: searchedItem,
            excludedItem: excludedItem,
            otherCategoryItem: otherCategoryItem
        )
    }
}
