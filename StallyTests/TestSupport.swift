import Foundation
import SwiftData
@testable import StallyLibrary
import XCTest

@MainActor
func testContext() -> ModelContext {
    do {
        return .init(
            try .init(
                for: Item.self,
                Mark.self,
                configurations: .init(
                    isStoredInMemoryOnly: true
                )
            )
        )
    } catch {
        preconditionFailure("Failed to create test context: \(error)")
    }
}

func localDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 12
) -> Date {
    var components: DateComponents = .init()
    components.calendar = .current
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour

    guard let date = components.date else {
        preconditionFailure("Failed to build date from \(components).")
    }

    return date
}

@MainActor
func createTestItem(
    context: ModelContext,
    name: String,
    category: ItemCategory,
    note: String? = nil,
    photoData: Data? = nil,
    createdAt: Date = .now
) throws -> Item {
    try ItemService.create(
        context: context,
        input: .init(
            name: name,
            category: category,
            photoData: photoData,
            note: note
        ),
        createdAt: createdAt
    )
}

@MainActor
@discardableResult
func markTestItem(
    context: ModelContext,
    item: Item,
    on date: Date
) throws -> Mark {
    try MarkService.mark(
        context: context,
        item: item,
        on: date
    )
}

@MainActor
func archiveTestItem(
    context: ModelContext,
    item: Item,
    at date: Date
) throws {
    try ItemService.archive(
        context: context,
        item: item,
        at: date
    )
}

@MainActor
func fetchItems(
    context: ModelContext
) throws -> [Item] {
    try context.fetch(
        .init(
            sortBy: [
                SortDescriptor(\Item.createdAt)
            ]
        )
    )
}
