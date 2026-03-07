import SwiftData
@testable import StallyLibrary
import XCTest

@MainActor
final class MarkServiceTests: XCTestCase {
    func testMarkIsIdempotentForTheSameItemAndDay() throws {
        let context = testContext()
        let item = try ItemService.create(
            context: context,
            input: .init(
                name: "Rain Jacket",
                category: .clothing
            )
        )

        _ = try MarkService.mark(
            context: context,
            item: item,
            on: localDate(year: 2026, month: 3, day: 8, hour: 9)
        )
        _ = try MarkService.mark(
            context: context,
            item: item,
            on: localDate(year: 2026, month: 3, day: 8, hour: 21)
        )

        XCTAssertEqual(item.marks.count, 1)
        XCTAssertEqual(
            try context.fetchCount(FetchDescriptor<Mark>()),
            1
        )
    }

    func testUnmarkRemovesOnlyTodayMark() throws {
        let context = testContext()
        let item = try ItemService.create(
            context: context,
            input: .init(
                name: "Runner",
                category: .shoes
            )
        )

        _ = try MarkService.mark(
            context: context,
            item: item,
            on: localDate(year: 2026, month: 3, day: 2)
        )
        _ = try MarkService.mark(
            context: context,
            item: item,
            on: localDate(year: 2026, month: 3, day: 8)
        )

        let didUnmark = try MarkService.unmark(
            context: context,
            item: item,
            on: localDate(year: 2026, month: 3, day: 8, hour: 18)
        )

        XCTAssertTrue(didUnmark)
        XCTAssertEqual(item.marks.count, 1)

        let summary = ItemInsightsCalculator.summary(
            for: item,
            referenceDate: localDate(year: 2026, month: 3, day: 8)
        )

        XCTAssertEqual(summary.totalMarks, 1)
        XCTAssertFalse(summary.isMarkedToday)
        XCTAssertTrue(
            Calendar.current.isDate(
                summary.lastMarkedAt ?? .distantPast,
                inSameDayAs: localDate(year: 2026, month: 3, day: 2)
            )
        )
    }

    func testMarkRejectsArchivedItemsAndPreservesExistingMarks() throws {
        let context = testContext()
        let item = try ItemService.create(
            context: context,
            input: .init(
                name: "Travel Coat",
                category: .clothing
            )
        )
        _ = try MarkService.mark(
            context: context,
            item: item,
            on: localDate(year: 2026, month: 3, day: 4)
        )
        try ItemService.archive(
            context: context,
            item: item,
            at: localDate(year: 2026, month: 3, day: 8)
        )

        XCTAssertThrowsError(
            try MarkService.mark(
                context: context,
                item: item,
                on: localDate(year: 2026, month: 3, day: 8)
            )
        ) { error in
            XCTAssertEqual(
                error as? MarkService.MutationError,
                .archivedItem
            )
        }
        XCTAssertEqual(item.marks.count, 1)
        XCTAssertEqual(
            try context.fetchCount(FetchDescriptor<Mark>()),
            1
        )
    }

    func testToggleRejectsArchivedItemsAndPreservesExistingMarks() throws {
        let context = testContext()
        let item = try ItemService.create(
            context: context,
            input: .init(
                name: "Weekend Sneaker",
                category: .shoes
            )
        )
        _ = try MarkService.mark(
            context: context,
            item: item,
            on: localDate(year: 2026, month: 3, day: 3)
        )
        try ItemService.archive(
            context: context,
            item: item,
            at: localDate(year: 2026, month: 3, day: 8)
        )

        XCTAssertThrowsError(
            try MarkService.toggle(
                context: context,
                item: item,
                on: localDate(year: 2026, month: 3, day: 8)
            )
        ) { error in
            XCTAssertEqual(
                error as? MarkService.MutationError,
                .archivedItem
            )
        }
        XCTAssertEqual(item.marks.count, 1)
        XCTAssertEqual(
            try context.fetchCount(FetchDescriptor<Mark>()),
            1
        )
    }

    func testUnmarkRejectsArchivedItemsAndPreservesExistingMarks() throws {
        let context = testContext()
        let item = try ItemService.create(
            context: context,
            input: .init(
                name: "Daily Tote",
                category: .bags
            )
        )
        _ = try MarkService.mark(
            context: context,
            item: item,
            on: localDate(year: 2026, month: 3, day: 5)
        )
        try ItemService.archive(
            context: context,
            item: item,
            at: localDate(year: 2026, month: 3, day: 8)
        )

        XCTAssertThrowsError(
            try MarkService.unmark(
                context: context,
                item: item,
                on: localDate(year: 2026, month: 3, day: 5)
            )
        ) { error in
            XCTAssertEqual(
                error as? MarkService.MutationError,
                .archivedItem
            )
        }
        XCTAssertEqual(item.marks.count, 1)
        XCTAssertEqual(
            try context.fetchCount(FetchDescriptor<Mark>()),
            1
        )
    }

    func testMarkAndUnmarkSupportArbitraryHistoryDates() throws {
        let context = testContext()
        let item = try ItemService.create(
            context: context,
            input: .init(
                name: "Field Journal",
                category: .notebooks
            )
        )
        let historyDate = localDate(year: 2026, month: 2, day: 27)

        _ = try MarkService.mark(
            context: context,
            item: item,
            on: historyDate
        )

        XCTAssertTrue(
            ItemInsightsCalculator.summary(
                for: item,
                referenceDate: historyDate
            ).isMarkedToday
        )

        _ = try MarkService.unmark(
            context: context,
            item: item,
            on: historyDate
        )

        XCTAssertFalse(
            ItemInsightsCalculator.summary(
                for: item,
                referenceDate: historyDate
            ).isMarkedToday
        )
        XCTAssertEqual(item.marks.count, 0)
    }
}
