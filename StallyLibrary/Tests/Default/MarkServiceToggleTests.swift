import SwiftData
@testable import StallyLibrary
import XCTest

@MainActor
final class MarkServiceToggleTests: XCTestCase {
    func testToggleCreatesThenRemovesMarkForTheSameStorageDay() throws {
        let context = testContext()
        let item = try ItemService.create(
            context: context,
            input: .init(
                name: "Daily Tote",
                category: .bags
            )
        )

        let didCreateMark = try MarkService.toggle(
            context: context,
            item: item,
            on: localDate(year: 2_026, month: 3, day: 8, hour: 9)
        )
        let didKeepMark = try MarkService.toggle(
            context: context,
            item: item,
            on: localDate(year: 2_026, month: 3, day: 8, hour: 21)
        )

        XCTAssertTrue(didCreateMark)
        XCTAssertFalse(didKeepMark)
        XCTAssertEqual(item.marks.count, 0)
        XCTAssertEqual(
            try context.fetchCount(FetchDescriptor<Mark>()),
            0
        )
    }

    func testToggleOnlyMutatesTheRequestedDay() throws {
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
            on: localDate(year: 2_026, month: 3, day: 7)
        )
        _ = try MarkService.mark(
            context: context,
            item: item,
            on: localDate(year: 2_026, month: 3, day: 8)
        )

        let didKeepMark = try MarkService.toggle(
            context: context,
            item: item,
            on: localDate(year: 2_026, month: 3, day: 8, hour: 18)
        )

        XCTAssertFalse(didKeepMark)
        XCTAssertEqual(item.marks.count, 1)
        XCTAssertEqual(
            try context.fetchCount(FetchDescriptor<Mark>()),
            1
        )

        let summary = ItemInsightsCalculator.summary(
            for: item,
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        XCTAssertEqual(summary.totalMarks, 1)
        XCTAssertFalse(summary.isMarkedToday)
        XCTAssertTrue(
            Calendar.current.isDate(
                summary.lastMarkedAt ?? .distantPast,
                inSameDayAs: localDate(year: 2_026, month: 3, day: 7)
            )
        )
    }
}
