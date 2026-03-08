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
        preconditionFailure("Failed to build a local date from \(components).")
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
func archiveTestItems(
    context: ModelContext,
    items: [Item],
    at date: Date
) throws {
    try ItemService.archive(
        context: context,
        items: items,
        at: date
    )
}

@MainActor
func unarchiveTestItem(
    context: ModelContext,
    item: Item,
    at date: Date
) throws {
    try ItemService.unarchive(
        context: context,
        item: item,
        at: date
    )
}

@MainActor
func unarchiveTestItems(
    context: ModelContext,
    items: [Item],
    at date: Date
) throws {
    try ItemService.unarchive(
        context: context,
        items: items,
        at: date
    )
}

func testUUID(
    _ value: String
) throws -> UUID {
    try XCTUnwrap(UUID(uuidString: value))
}

func makeBackupSnapshot(
    exportedAt: Date,
    items: [StallyBackupItem],
    schemaVersion: Int = StallyBackupSnapshot.currentSchemaVersion
) -> StallyBackupSnapshot {
    .init(
        exportedAt: exportedAt,
        items: items,
        schemaVersion: schemaVersion
    )
}

func makeBackupItem(
    id: String,
    name: String,
    categoryRawValue: String,
    createdAt: Date = .now,
    photoData: Data? = nil,
    note: String? = nil,
    updatedAt: Date? = nil,
    archivedAt: Date? = nil,
    marks: [StallyBackupMark] = []
) throws -> StallyBackupItem {
    .init(
        id: try testUUID(id),
        name: name,
        categoryRawValue: categoryRawValue,
        photoData: photoData,
        note: note,
        createdAt: createdAt,
        updatedAt: updatedAt ?? createdAt,
        archivedAt: archivedAt,
        marks: marks
    )
}

func makeBackupMark(
    id: String,
    day: Date,
    createdAt: Date? = nil
) throws -> StallyBackupMark {
    .init(
        id: try testUUID(id),
        day: day,
        createdAt: createdAt ?? day
    )
}

func makeStoredItem(
    name: String,
    category: ItemCategory,
    createdAt: Date = .now,
    photoData: Data? = nil,
    note: String? = nil,
    updatedAt: Date? = nil,
    archivedAt: Date? = nil,
    id: String? = nil
) throws -> Item {
    let resolvedID: UUID
    if let id {
        resolvedID = try testUUID(id)
    } else {
        resolvedID = .init()
    }

    return Item(
        name: name,
        category: category,
        photoData: photoData,
        note: note,
        createdAt: createdAt,
        updatedAt: updatedAt,
        archivedAt: archivedAt,
        id: resolvedID
    )
}

func makeStoredMark(
    id: String,
    item: Item,
    day: Date,
    createdAt: Date? = nil
) throws -> Mark {
    Mark(
        item: item,
        day: DayStamp.storageDate(from: day),
        createdAt: createdAt ?? day,
        id: try testUUID(id)
    )
}
