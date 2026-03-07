@testable import StallyLibrary
import XCTest

@MainActor
final class ItemInsightsCalculatorTests: XCTestCase {
    func testSummaryReturnsTotalLastMarkedDateAndTodayState() throws {
        let context = testContext()
        let item = try ItemService.create(
            context: context,
            input: .init(
                name: "Crossbody Bag",
                category: .bags
            )
        )

        _ = try MarkService.mark(
            context: context,
            item: item,
            on: localDate(year: 2026, month: 3, day: 1)
        )
        _ = try MarkService.mark(
            context: context,
            item: item,
            on: localDate(year: 2026, month: 3, day: 8)
        )

        let summary = ItemInsightsCalculator.summary(
            for: item,
            referenceDate: localDate(year: 2026, month: 3, day: 8, hour: 19)
        )

        XCTAssertEqual(summary.totalMarks, 2)
        XCTAssertTrue(summary.isMarkedToday)
        XCTAssertTrue(
            Calendar.current.isDate(
                summary.lastMarkedAt ?? .distantPast,
                inSameDayAs: localDate(year: 2026, month: 3, day: 8)
            )
        )
    }

    func testArchiveFilteringSeparatesActiveAndArchivedItems() throws {
        let context = testContext()
        let activeItem = try ItemService.create(
            context: context,
            input: .init(
                name: "Grey Tee",
                category: .clothing
            )
        )
        let archivedItem = try ItemService.create(
            context: context,
            input: .init(
                name: "Weekend Tote",
                category: .bags
            )
        )

        try ItemService.archive(
            context: context,
            item: archivedItem,
            at: localDate(year: 2026, month: 3, day: 8)
        )

        XCTAssertEqual(
            ItemInsightsCalculator.activeItems(
                from: [activeItem, archivedItem]
            ).map(\.id),
            [activeItem.id]
        )
        XCTAssertEqual(
            ItemInsightsCalculator.archivedItems(
                from: [activeItem, archivedItem]
            ).map(\.id),
            [archivedItem.id]
        )
    }

    func testItemListQueryFiltersSearchAndCategoryThenSortsByMostMarked() throws {
        let context = testContext()
        let searchedItem = try ItemService.create(
            context: context,
            input: .init(
                name: "Office Tote",
                category: .bags,
                note: "Carries my notebook."
            ),
            createdAt: localDate(year: 2026, month: 3, day: 1)
        )
        let excludedItem = try ItemService.create(
            context: context,
            input: .init(
                name: "Weekend Tote",
                category: .bags,
                note: "For short trips."
            ),
            createdAt: localDate(year: 2026, month: 3, day: 2)
        )
        let otherCategoryItem = try ItemService.create(
            context: context,
            input: .init(
                name: "Daily Notebook",
                category: .notebooks,
                note: "Office notes."
            ),
            createdAt: localDate(year: 2026, month: 3, day: 3)
        )

        _ = try MarkService.mark(
            context: context,
            item: searchedItem,
            on: localDate(year: 2026, month: 3, day: 4)
        )
        _ = try MarkService.mark(
            context: context,
            item: searchedItem,
            on: localDate(year: 2026, month: 3, day: 6)
        )
        _ = try MarkService.mark(
            context: context,
            item: excludedItem,
            on: localDate(year: 2026, month: 3, day: 5)
        )
        _ = try MarkService.mark(
            context: context,
            item: otherCategoryItem,
            on: localDate(year: 2026, month: 3, day: 7)
        )

        let results = ItemInsightsCalculator.items(
            from: [otherCategoryItem, excludedItem, searchedItem],
            matching: .init(
                searchText: "office",
                category: .bags,
                sortOption: .mostMarked
            ),
            kind: .active,
            referenceDate: localDate(year: 2026, month: 3, day: 8)
        )

        XCTAssertEqual(results.map(\.id), [searchedItem.id])
    }

    func testItemListQueryPreservesArchivedDefaultOrder() throws {
        let context = testContext()
        let earlierArchivedItem = try ItemService.create(
            context: context,
            input: .init(
                name: "Old Coat",
                category: .clothing
            ),
            createdAt: localDate(year: 2026, month: 2, day: 1)
        )
        let laterArchivedItem = try ItemService.create(
            context: context,
            input: .init(
                name: "Recent Coat",
                category: .clothing
            ),
            createdAt: localDate(year: 2026, month: 2, day: 2)
        )

        try ItemService.archive(
            context: context,
            item: earlierArchivedItem,
            at: localDate(year: 2026, month: 3, day: 4)
        )
        try ItemService.archive(
            context: context,
            item: laterArchivedItem,
            at: localDate(year: 2026, month: 3, day: 8)
        )

        let results = ItemInsightsCalculator.items(
            from: [earlierArchivedItem, laterArchivedItem],
            matching: .init(
                category: .clothing,
                sortOption: .defaultOrder
            ),
            kind: .archived,
            referenceDate: localDate(year: 2026, month: 3, day: 8)
        )

        XCTAssertEqual(
            results.map(\.id),
            [laterArchivedItem.id, earlierArchivedItem.id]
        )
    }
}
