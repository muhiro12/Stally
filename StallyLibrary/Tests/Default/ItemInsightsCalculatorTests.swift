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
}
