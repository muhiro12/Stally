import SwiftData
@testable import StallyLibrary
import XCTest

@MainActor
final class ItemServiceTests: XCTestCase {
    func testCreateNormalizesInputBeforeSaving() throws {
        let context = testContext()

        let item = try ItemService.create(
            context: context,
            input: .init(
                name: "  Indigo Shirt  ",
                category: .clothing,
                photoData: Data(),
                note: "  Favorite fit  "
            )
        )

        XCTAssertEqual(item.name, "Indigo Shirt")
        XCTAssertEqual(item.note, "Favorite fit")
        XCTAssertNil(item.photoData)
    }

    func testSeedSampleDataDoesNotDuplicateWhenIfEmptyOnlyIsTrue() throws {
        let context = testContext()

        try ItemService.seedSampleData(
            context: context,
            ifEmptyOnly: true,
            referenceDate: localDate(year: 2026, month: 3, day: 8)
        )

        let firstItemCount = try context.fetchCount(FetchDescriptor<Item>())
        let firstMarkCount = try context.fetchCount(FetchDescriptor<Mark>())

        try ItemService.seedSampleData(
            context: context,
            ifEmptyOnly: true,
            referenceDate: localDate(year: 2026, month: 3, day: 8)
        )

        XCTAssertEqual(
            try context.fetchCount(FetchDescriptor<Item>()),
            firstItemCount
        )
        XCTAssertEqual(
            try context.fetchCount(FetchDescriptor<Mark>()),
            firstMarkCount
        )
        XCTAssertGreaterThan(firstItemCount, 0)
        XCTAssertGreaterThan(firstMarkCount, 0)
    }
}
