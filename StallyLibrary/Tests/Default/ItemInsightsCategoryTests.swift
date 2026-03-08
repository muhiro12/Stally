@testable import StallyLibrary
import XCTest

@MainActor
final class ItemInsightsCategoryTests: XCTestCase {
    func testCategorySummariesAggregateMarksItemsAndShareOfMarks() throws {
        let context = testContext()
        let clothingA = try createTestItem(
            context: context,
            name: "Black Tee",
            category: .clothing
        )
        let clothingB = try createTestItem(
            context: context,
            name: "Grey Tee",
            category: .clothing
        )
        let bag = try createTestItem(
            context: context,
            name: "Canvas Tote",
            category: .bags
        )

        for item in [clothingA, clothingB] {
            _ = try markTestItem(
                context: context,
                item: item,
                on: localDate(year: 2_026, month: 3, day: 5)
            )
        }
        _ = try markTestItem(
            context: context,
            item: clothingA,
            on: localDate(year: 2_026, month: 3, day: 8)
        )
        _ = try markTestItem(
            context: context,
            item: bag,
            on: localDate(year: 2_026, month: 3, day: 7)
        )

        let summaries = ItemInsightsCalculator.categorySummaries(
            from: [clothingA, clothingB, bag],
            range: .last30Days,
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        XCTAssertEqual(summaries.map(\.category), [.clothing, .bags])
        XCTAssertEqual(summaries.first?.totalMarks, 3)
        XCTAssertEqual(summaries.first?.uniqueItems, 2)
        XCTAssertEqual(summaries.first?.shareOfMarks, 0.75)
        XCTAssertTrue(
            Calendar.current.isDate(
                summaries.first?.lastMarkedAt ?? .distantPast,
                inSameDayAs: localDate(year: 2_026, month: 3, day: 8)
            )
        )
        XCTAssertEqual(summaries.last?.totalMarks, 1)
    }

    func testCategorySummariesOptionallyIncludeArchivedMarks() throws {
        let context = testContext()
        let activeItem = try createTestItem(
            context: context,
            name: "Active Coat",
            category: .clothing
        )
        let archivedItem = try createTestItem(
            context: context,
            name: "Stored Sneakers",
            category: .shoes
        )

        _ = try markTestItem(
            context: context,
            item: activeItem,
            on: localDate(year: 2_026, month: 3, day: 4)
        )
        _ = try markTestItem(
            context: context,
            item: archivedItem,
            on: localDate(year: 2_026, month: 3, day: 5)
        )
        try archiveTestItem(
            context: context,
            item: archivedItem,
            at: localDate(year: 2_026, month: 3, day: 6)
        )

        let activeOnly = ItemInsightsCalculator.categorySummaries(
            from: [activeItem, archivedItem],
            range: .last30Days,
            includeArchivedItems: false,
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )
        let includingArchived = ItemInsightsCalculator.categorySummaries(
            from: [activeItem, archivedItem],
            range: .last30Days,
            includeArchivedItems: true,
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        XCTAssertEqual(activeOnly.map(\.category), [.clothing])
        XCTAssertEqual(includingArchived.map(\.category), [.shoes, .clothing])
    }

    func testCategorySummariesIgnoreMarksOutsideTheSelectedWindow() throws {
        let context = testContext()
        let item = try createTestItem(
            context: context,
            name: "Old Notebook",
            category: .notebooks
        )

        _ = try markTestItem(
            context: context,
            item: item,
            on: localDate(year: 2_026, month: 1, day: 1)
        )

        let summaries = ItemInsightsCalculator.categorySummaries(
            from: [item],
            range: .last30Days,
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        XCTAssertTrue(summaries.isEmpty)
    }
}
