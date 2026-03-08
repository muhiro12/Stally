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

    func testActiveSummaryCountsMarkedTodayUntouchedItemsAndTotalMarks() throws {
        let context = testContext()
        let markedTodayItem = try ItemService.create(
            context: context,
            input: .init(
                name: "Black Tee",
                category: .clothing
            )
        )
        let previouslyMarkedItem = try ItemService.create(
            context: context,
            input: .init(
                name: "Canvas Tote",
                category: .bags
            )
        )
        let untouchedItem = try ItemService.create(
            context: context,
            input: .init(
                name: "Pocket Notebook",
                category: .notebooks
            )
        )

        _ = try MarkService.mark(
            context: context,
            item: markedTodayItem,
            on: localDate(year: 2026, month: 3, day: 8)
        )
        _ = try MarkService.mark(
            context: context,
            item: previouslyMarkedItem,
            on: localDate(year: 2026, month: 3, day: 6)
        )
        _ = try MarkService.mark(
            context: context,
            item: previouslyMarkedItem,
            on: localDate(year: 2026, month: 3, day: 7)
        )

        let summary = ItemInsightsCalculator.activeSummary(
            from: [markedTodayItem, previouslyMarkedItem, untouchedItem],
            referenceDate: localDate(year: 2026, month: 3, day: 8, hour: 20)
        )

        XCTAssertEqual(summary.totalItems, 3)
        XCTAssertEqual(summary.markedTodayCount, 1)
        XCTAssertEqual(summary.neverMarkedCount, 1)
        XCTAssertEqual(summary.totalMarks, 3)
    }

    func testArchiveSummaryTracksMarkedItemsAndLatestArchiveDate() throws {
        let context = testContext()
        let recentArchivedItem = try ItemService.create(
            context: context,
            input: .init(
                name: "Recent Coat",
                category: .clothing
            )
        )
        let olderArchivedItem = try ItemService.create(
            context: context,
            input: .init(
                name: "Old Tote",
                category: .bags
            )
        )
        let activeItem = try ItemService.create(
            context: context,
            input: .init(
                name: "Active Notebook",
                category: .notebooks
            )
        )

        _ = try MarkService.mark(
            context: context,
            item: recentArchivedItem,
            on: localDate(year: 2026, month: 3, day: 4)
        )
        _ = try MarkService.mark(
            context: context,
            item: olderArchivedItem,
            on: localDate(year: 2026, month: 3, day: 1)
        )
        _ = try MarkService.mark(
            context: context,
            item: olderArchivedItem,
            on: localDate(year: 2026, month: 3, day: 2)
        )

        try ItemService.archive(
            context: context,
            item: olderArchivedItem,
            at: localDate(year: 2026, month: 3, day: 3)
        )
        try ItemService.archive(
            context: context,
            item: recentArchivedItem,
            at: localDate(year: 2026, month: 3, day: 8)
        )

        let summary = ItemInsightsCalculator.archiveSummary(
            from: [olderArchivedItem, activeItem, recentArchivedItem]
        )

        XCTAssertEqual(summary.totalItems, 2)
        XCTAssertEqual(summary.itemsWithMarksCount, 2)
        XCTAssertEqual(summary.totalMarks, 3)
        XCTAssertTrue(
            Calendar.current.isDate(
                summary.lastArchivedAt ?? .distantPast,
                inSameDayAs: localDate(year: 2026, month: 3, day: 8)
            )
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

    func testItemListQueryQuickFilterSeparatesMarkedAndOpenItemsForReferenceDay() throws {
        let context = testContext()
        let markedTodayItem = try ItemService.create(
            context: context,
            input: .init(
                name: "Marked Tee",
                category: .clothing
            )
        )
        let openTodayItem = try ItemService.create(
            context: context,
            input: .init(
                name: "Open Tee",
                category: .clothing
            )
        )

        _ = try MarkService.mark(
            context: context,
            item: markedTodayItem,
            on: localDate(year: 2026, month: 3, day: 8)
        )
        _ = try MarkService.mark(
            context: context,
            item: openTodayItem,
            on: localDate(year: 2026, month: 3, day: 6)
        )

        let markedResults = ItemInsightsCalculator.items(
            from: [openTodayItem, markedTodayItem],
            matching: .init(
                quickFilter: .markedOnReferenceDay
            ),
            kind: .active,
            referenceDate: localDate(year: 2026, month: 3, day: 8)
        )
        let openResults = ItemInsightsCalculator.items(
            from: [openTodayItem, markedTodayItem],
            matching: .init(
                quickFilter: .unmarkedOnReferenceDay
            ),
            kind: .active,
            referenceDate: localDate(year: 2026, month: 3, day: 8)
        )

        XCTAssertEqual(markedResults.map(\.id), [markedTodayItem.id])
        XCTAssertEqual(openResults.map(\.id), [openTodayItem.id])
    }

    func testItemListQueryQuickFilterSeparatesItemsWithAndWithoutHistory() throws {
        let context = testContext()
        let withHistoryItem = try ItemService.create(
            context: context,
            input: .init(
                name: "History Tote",
                category: .bags
            )
        )
        let withoutHistoryItem = try ItemService.create(
            context: context,
            input: .init(
                name: "Fresh Tote",
                category: .bags
            )
        )
        let archivedItem = try ItemService.create(
            context: context,
            input: .init(
                name: "Archived Tote",
                category: .bags
            )
        )

        _ = try MarkService.mark(
            context: context,
            item: withHistoryItem,
            on: localDate(year: 2026, month: 3, day: 5)
        )
        _ = try MarkService.mark(
            context: context,
            item: archivedItem,
            on: localDate(year: 2026, month: 3, day: 2)
        )
        try ItemService.archive(
            context: context,
            item: archivedItem,
            at: localDate(year: 2026, month: 3, day: 6)
        )

        let activeWithoutHistory = ItemInsightsCalculator.items(
            from: [withHistoryItem, withoutHistoryItem, archivedItem],
            matching: .init(
                quickFilter: .withoutHistory
            ),
            kind: .active,
            referenceDate: localDate(year: 2026, month: 3, day: 8)
        )
        let archivedWithHistory = ItemInsightsCalculator.items(
            from: [withHistoryItem, withoutHistoryItem, archivedItem],
            matching: .init(
                quickFilter: .withHistory
            ),
            kind: .archived,
            referenceDate: localDate(year: 2026, month: 3, day: 8)
        )

        XCTAssertEqual(activeWithoutHistory.map(\.id), [withoutHistoryItem.id])
        XCTAssertEqual(archivedWithHistory.map(\.id), [archivedItem.id])
    }
}
