import SwiftData
@testable import StallyLibrary
import XCTest

@MainActor
final class ItemServiceDeletionTests: XCTestCase {
    func testDeleteRemovesOneItemAndItsMarks() throws {
        let context = testContext()
        let deletedItem = try createTestItem(
            context: context,
            name: "Delete Me",
            category: .bags
        )
        let keptItem = try createTestItem(
            context: context,
            name: "Keep Me",
            category: .clothing
        )

        _ = try markTestItem(
            context: context,
            item: deletedItem,
            on: localDate(year: 2_026, month: 3, day: 7)
        )
        _ = try markTestItem(
            context: context,
            item: keptItem,
            on: localDate(year: 2_026, month: 3, day: 8)
        )

        try ItemService.delete(
            context: context,
            item: deletedItem
        )

        let remainingItems = try context.fetch(FetchDescriptor<Item>())
        let remainingMarks = try context.fetch(FetchDescriptor<Mark>())

        XCTAssertEqual(remainingItems.map(\.id), [keptItem.id])
        XCTAssertEqual(remainingMarks.count, 1)
        XCTAssertEqual(remainingMarks.first?.item.id, keptItem.id)
    }

    func testDeleteAllClearsItemsAndMarksAndNoOpsWhenEmpty() throws {
        let context = testContext()
        let coat = try createTestItem(
            context: context,
            name: "Coat",
            category: .clothing
        )
        let tote = try createTestItem(
            context: context,
            name: "Tote",
            category: .bags
        )

        _ = try markTestItem(
            context: context,
            item: coat,
            on: localDate(year: 2_026, month: 3, day: 6)
        )
        _ = try markTestItem(
            context: context,
            item: tote,
            on: localDate(year: 2_026, month: 3, day: 8)
        )

        try ItemService.deleteAll(
            context: context
        )
        try ItemService.deleteAll(
            context: context
        )

        XCTAssertEqual(
            try context.fetchCount(FetchDescriptor<Item>()),
            0
        )
        XCTAssertEqual(
            try context.fetchCount(FetchDescriptor<Mark>()),
            0
        )
    }
}
