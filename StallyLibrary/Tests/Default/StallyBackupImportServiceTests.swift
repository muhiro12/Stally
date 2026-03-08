import Foundation
import SwiftData
@testable import StallyLibrary
import XCTest

@MainActor
final class StallyBackupImportServiceTests: XCTestCase {
    func testMergeCreatesItemsMarksAndArchiveState() throws {
        let context = testContext()
        let archivedItemID = try XCTUnwrap(
            UUID(uuidString: "30000000-0000-0000-0000-000000000001")
        )
        let snapshot = StallyBackupSnapshot(
            exportedAt: localDate(year: 2026, month: 3, day: 8),
            items: [
                .init(
                    id: archivedItemID,
                    name: "Travel Weekender",
                    categoryRawValue: ItemCategory.bags.rawValue,
                    photoData: nil,
                    note: "Stored for seasonal trips.",
                    createdAt: localDate(year: 2025, month: 10, day: 1),
                    updatedAt: localDate(year: 2026, month: 1, day: 15),
                    archivedAt: localDate(year: 2026, month: 1, day: 15),
                    marks: [
                        .init(
                            id: try XCTUnwrap(UUID(uuidString: "40000000-0000-0000-0000-000000000001")),
                            day: localDate(year: 2025, month: 12, day: 20),
                            createdAt: localDate(year: 2025, month: 12, day: 20)
                        )
                    ]
                ),
                .init(
                    id: try XCTUnwrap(UUID(uuidString: "30000000-0000-0000-0000-000000000002")),
                    name: "Unknown Category Piece",
                    categoryRawValue: "headwear",
                    photoData: Data([0x0A, 0x0B]),
                    note: nil,
                    createdAt: localDate(year: 2026, month: 2, day: 1),
                    updatedAt: localDate(year: 2026, month: 2, day: 3),
                    archivedAt: nil,
                    marks: []
                )
            ]
        )

        let result = try StallyBackupImportService.merge(
            context: context,
            snapshot: snapshot
        )
        let items = try context.fetch(FetchDescriptor<Item>())

        XCTAssertEqual(result.createdItems, 2)
        XCTAssertEqual(result.deletedItems, 0)
        XCTAssertEqual(result.updatedItems, 0)
        XCTAssertEqual(result.insertedMarks, 1)
        XCTAssertEqual(result.skippedMarks, 0)
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(
            try context.fetchCount(FetchDescriptor<Mark>()),
            1
        )
        XCTAssertEqual(
            items.first(where: { $0.id == archivedItemID })?.archivedAt,
            localDate(year: 2026, month: 1, day: 15)
        )
        XCTAssertEqual(
            items.first(where: { $0.name == "Unknown Category Piece" })?.category,
            .other
        )
    }

    func testMergeUpdatesOlderLocalItemAndSkipsDuplicateMarkDays() throws {
        let context = testContext()
        let itemID = try XCTUnwrap(
            UUID(uuidString: "50000000-0000-0000-0000-000000000001")
        )
        let localItem = Item(
            id: itemID,
            name: "Old Name",
            category: .other,
            photoData: nil,
            note: "Old note",
            createdAt: localDate(year: 2026, month: 1, day: 1),
            updatedAt: localDate(year: 2026, month: 1, day: 10)
        )
        let localMark = Mark(
            id: try XCTUnwrap(UUID(uuidString: "60000000-0000-0000-0000-000000000001")),
            item: localItem,
            day: DayStamp.storageDate(from: localDate(year: 2026, month: 2, day: 1)),
            createdAt: localDate(year: 2026, month: 2, day: 1)
        )
        context.insert(localItem)
        context.insert(localMark)
        try context.save()

        let snapshot = StallyBackupSnapshot(
            exportedAt: localDate(year: 2026, month: 3, day: 8),
            items: [
                .init(
                    id: itemID,
                    name: "Imported Name",
                    categoryRawValue: ItemCategory.clothing.rawValue,
                    photoData: Data([0x01]),
                    note: "Imported note",
                    createdAt: localDate(year: 2025, month: 12, day: 20),
                    updatedAt: localDate(year: 2026, month: 2, day: 20),
                    archivedAt: localDate(year: 2026, month: 2, day: 25),
                    marks: [
                        .init(
                            id: try XCTUnwrap(UUID(uuidString: "60000000-0000-0000-0000-000000000002")),
                            day: localDate(year: 2026, month: 2, day: 1),
                            createdAt: localDate(year: 2026, month: 2, day: 1)
                        ),
                        .init(
                            id: try XCTUnwrap(UUID(uuidString: "60000000-0000-0000-0000-000000000003")),
                            day: localDate(year: 2026, month: 2, day: 4),
                            createdAt: localDate(year: 2026, month: 2, day: 4)
                        )
                    ]
                )
            ]
        )

        let result = try StallyBackupImportService.merge(
            context: context,
            snapshot: snapshot
        )

        XCTAssertEqual(result.createdItems, 0)
        XCTAssertEqual(result.deletedItems, 0)
        XCTAssertEqual(result.updatedItems, 1)
        XCTAssertEqual(result.insertedMarks, 1)
        XCTAssertEqual(result.skippedMarks, 1)
        XCTAssertEqual(localItem.name, "Imported Name")
        XCTAssertEqual(localItem.category, .clothing)
        XCTAssertEqual(localItem.note, "Imported note")
        XCTAssertEqual(localItem.photoData, Data([0x01]))
        XCTAssertEqual(localItem.archivedAt, localDate(year: 2026, month: 2, day: 25))
        XCTAssertEqual(localItem.marks.count, 2)
    }

    func testMergePreservesNewerLocalMetadataWhileAddingMissingMarks() throws {
        let context = testContext()
        let itemID = try XCTUnwrap(
            UUID(uuidString: "70000000-0000-0000-0000-000000000001")
        )
        let localItem = Item(
            id: itemID,
            name: "Local Favorite",
            category: .shoes,
            photoData: nil,
            note: "Newer local metadata.",
            createdAt: localDate(year: 2026, month: 1, day: 1),
            updatedAt: localDate(year: 2026, month: 3, day: 1)
        )
        context.insert(localItem)
        try context.save()

        let snapshot = StallyBackupSnapshot(
            exportedAt: localDate(year: 2026, month: 3, day: 8),
            items: [
                .init(
                    id: itemID,
                    name: "Older Imported Name",
                    categoryRawValue: ItemCategory.bags.rawValue,
                    photoData: nil,
                    note: "Older backup metadata.",
                    createdAt: localDate(year: 2025, month: 12, day: 20),
                    updatedAt: localDate(year: 2026, month: 2, day: 1),
                    archivedAt: localDate(year: 2026, month: 2, day: 2),
                    marks: [
                        .init(
                            id: try XCTUnwrap(UUID(uuidString: "80000000-0000-0000-0000-000000000001")),
                            day: localDate(year: 2026, month: 2, day: 8),
                            createdAt: localDate(year: 2026, month: 2, day: 8)
                        )
                    ]
                )
            ]
        )

        let result = try StallyBackupImportService.merge(
            context: context,
            snapshot: snapshot
        )

        XCTAssertEqual(result.createdItems, 0)
        XCTAssertEqual(result.deletedItems, 0)
        XCTAssertEqual(result.updatedItems, 0)
        XCTAssertEqual(result.insertedMarks, 1)
        XCTAssertEqual(localItem.name, "Local Favorite")
        XCTAssertEqual(localItem.category, .shoes)
        XCTAssertEqual(localItem.note, "Newer local metadata.")
        XCTAssertNil(localItem.archivedAt)
        XCTAssertEqual(localItem.marks.count, 1)
    }

    func testReplaceDeletesExistingItemsBeforeImportingSnapshot() throws {
        let context = testContext()
        let existingItem = Item(
            name: "Local Item",
            category: .other,
            createdAt: localDate(year: 2026, month: 1, day: 1)
        )
        context.insert(existingItem)
        try context.save()

        let snapshot = StallyBackupSnapshot(
            exportedAt: localDate(year: 2026, month: 3, day: 8),
            items: [
                .init(
                    id: try XCTUnwrap(UUID(uuidString: "90000000-0000-0000-0000-000000000001")),
                    name: "Imported Replacement",
                    categoryRawValue: ItemCategory.notebooks.rawValue,
                    photoData: nil,
                    note: nil,
                    createdAt: localDate(year: 2026, month: 2, day: 2),
                    updatedAt: localDate(year: 2026, month: 2, day: 4),
                    archivedAt: nil,
                    marks: [
                        .init(
                            id: try XCTUnwrap(UUID(uuidString: "90000000-0000-0000-0000-000000000002")),
                            day: localDate(year: 2026, month: 2, day: 5),
                            createdAt: localDate(year: 2026, month: 2, day: 5)
                        )
                    ]
                )
            ]
        )

        let result = try StallyBackupImportService.replace(
            context: context,
            snapshot: snapshot
        )
        let items = try context.fetch(FetchDescriptor<Item>())

        XCTAssertEqual(result.deletedItems, 1)
        XCTAssertEqual(result.createdItems, 1)
        XCTAssertEqual(result.updatedItems, 0)
        XCTAssertEqual(result.insertedMarks, 1)
        XCTAssertEqual(items.map(\.name), ["Imported Replacement"])
        XCTAssertEqual(
            try context.fetchCount(FetchDescriptor<Mark>()),
            1
        )
    }

    func testReplaceRejectsInvalidSnapshotsWithoutDeletingLocalItems() throws {
        let context = testContext()
        let existingItem = Item(
            name: "Keep Me",
            category: .bags,
            createdAt: localDate(year: 2026, month: 1, day: 1)
        )
        context.insert(existingItem)
        try context.save()

        let duplicateID = try XCTUnwrap(
            UUID(uuidString: "A0000000-0000-0000-0000-000000000001")
        )
        let snapshot = StallyBackupSnapshot(
            exportedAt: localDate(year: 2026, month: 3, day: 8),
            items: [
                .init(
                    id: duplicateID,
                    name: "One",
                    categoryRawValue: ItemCategory.bags.rawValue,
                    photoData: nil,
                    note: nil,
                    createdAt: localDate(year: 2026, month: 2, day: 1),
                    updatedAt: localDate(year: 2026, month: 2, day: 1),
                    archivedAt: nil,
                    marks: []
                ),
                .init(
                    id: duplicateID,
                    name: "Two",
                    categoryRawValue: ItemCategory.shoes.rawValue,
                    photoData: nil,
                    note: nil,
                    createdAt: localDate(year: 2026, month: 2, day: 2),
                    updatedAt: localDate(year: 2026, month: 2, day: 2),
                    archivedAt: nil,
                    marks: []
                )
            ]
        )

        XCTAssertThrowsError(
            try StallyBackupImportService.replace(
                context: context,
                snapshot: snapshot
            )
        )
        XCTAssertEqual(
            try context.fetch(FetchDescriptor<Item>()).map(\.name),
            ["Keep Me"]
        )
    }
}
