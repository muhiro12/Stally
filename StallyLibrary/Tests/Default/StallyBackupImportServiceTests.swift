import Foundation
import SwiftData
@testable import StallyLibrary
import XCTest

@MainActor
final class StallyBackupImportServiceTests: XCTestCase {
    func testMergeCreatesItemsMarksAndArchiveState() throws {
        let context = testContext()
        let archivedItemID = try testUUID("30000000-0000-0000-0000-000000000001")
        let snapshot = try makeMergeCreatesSnapshot()

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
            items.first { $0.id == archivedItemID }?.archivedAt,
            localDate(year: 2_026, month: 1, day: 15)
        )
        XCTAssertEqual(
            items.first { $0.name == "Unknown Category Piece" }?.category,
            .other
        )
    }

    func testMergeUpdatesOlderLocalItemAndSkipsDuplicateMarkDays() throws {
        let context = testContext()
        let fixture = try makeMergeUpdatesFixture(context: context)

        let result = try StallyBackupImportService.merge(
            context: context,
            snapshot: fixture.snapshot
        )

        XCTAssertEqual(result.createdItems, 0)
        XCTAssertEqual(result.deletedItems, 0)
        XCTAssertEqual(result.updatedItems, 1)
        XCTAssertEqual(result.insertedMarks, 1)
        XCTAssertEqual(result.skippedMarks, 1)
        XCTAssertEqual(fixture.localItem.name, "Imported Name")
        XCTAssertEqual(fixture.localItem.category, .clothing)
        XCTAssertEqual(fixture.localItem.note, "Imported note")
        XCTAssertEqual(fixture.localItem.photoData, Data([0x01]))
        XCTAssertEqual(
            fixture.localItem.archivedAt,
            localDate(year: 2_026, month: 2, day: 25)
        )
        XCTAssertEqual(fixture.localItem.marks.count, 2)
    }

    func testMergePreservesNewerLocalMetadataWhileAddingMissingMarks() throws {
        let context = testContext()
        let itemID = try testUUID("70000000-0000-0000-0000-000000000001")
        let localItem = try makeStoredItem(
            name: "Local Favorite",
            category: .shoes,
            createdAt: localDate(year: 2_026, month: 1, day: 1),
            note: "Newer local metadata.",
            updatedAt: localDate(year: 2_026, month: 3, day: 1),
            id: "70000000-0000-0000-0000-000000000001"
        )
        context.insert(localItem)
        try context.save()

        let snapshot = makeBackupSnapshot(
            exportedAt: localDate(year: 2_026, month: 3, day: 8),
            items: [
                try makeBackupItem(
                    id: "70000000-0000-0000-0000-000000000001",
                    name: "Older Imported Name",
                    categoryRawValue: ItemCategory.bags.rawValue,
                    createdAt: localDate(year: 2_025, month: 12, day: 20),
                    note: "Older backup metadata.",
                    updatedAt: localDate(year: 2_026, month: 2, day: 1),
                    archivedAt: localDate(year: 2_026, month: 2, day: 2),
                    marks: [
                        try makeBackupMark(
                            id: "80000000-0000-0000-0000-000000000001",
                            day: localDate(year: 2_026, month: 2, day: 8)
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
        let existingItem = try makeStoredItem(
            name: "Local Item",
            category: .other,
            createdAt: localDate(year: 2_026, month: 1, day: 1)
        )
        context.insert(existingItem)
        try context.save()

        let snapshot = makeBackupSnapshot(
            exportedAt: localDate(year: 2_026, month: 3, day: 8),
            items: [
                try makeBackupItem(
                    id: "90000000-0000-0000-0000-000000000001",
                    name: "Imported Replacement",
                    categoryRawValue: ItemCategory.notebooks.rawValue,
                    createdAt: localDate(year: 2_026, month: 2, day: 2),
                    updatedAt: localDate(year: 2_026, month: 2, day: 4),
                    marks: [
                        try makeBackupMark(
                            id: "90000000-0000-0000-0000-000000000002",
                            day: localDate(year: 2_026, month: 2, day: 5)
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
        let existingItem = try makeStoredItem(
            name: "Keep Me",
            category: .bags,
            createdAt: localDate(year: 2_026, month: 1, day: 1)
        )
        context.insert(existingItem)
        try context.save()

        let snapshot = makeBackupSnapshot(
            exportedAt: localDate(year: 2_026, month: 3, day: 8),
            items: [
                try makeBackupItem(
                    id: "A0000000-0000-0000-0000-000000000001",
                    name: "One",
                    categoryRawValue: ItemCategory.bags.rawValue,
                    createdAt: localDate(year: 2_026, month: 2, day: 1),
                    updatedAt: localDate(year: 2_026, month: 2, day: 1)
                ),
                try makeBackupItem(
                    id: "A0000000-0000-0000-0000-000000000001",
                    name: "Two",
                    categoryRawValue: ItemCategory.shoes.rawValue,
                    createdAt: localDate(year: 2_026, month: 2, day: 2),
                    updatedAt: localDate(year: 2_026, month: 2, day: 2)
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

private func makeMergeCreatesSnapshot() throws -> StallyBackupSnapshot {
    makeBackupSnapshot(
        exportedAt: localDate(year: 2_026, month: 3, day: 8),
        items: [
            try makeBackupItem(
                id: "30000000-0000-0000-0000-000000000001",
                name: "Travel Weekender",
                categoryRawValue: ItemCategory.bags.rawValue,
                createdAt: localDate(year: 2_025, month: 10, day: 1),
                note: "Stored for seasonal trips.",
                updatedAt: localDate(year: 2_026, month: 1, day: 15),
                archivedAt: localDate(year: 2_026, month: 1, day: 15),
                marks: [
                    try makeBackupMark(
                        id: "40000000-0000-0000-0000-000000000001",
                        day: localDate(year: 2_025, month: 12, day: 20)
                    )
                ]
            ),
            try makeBackupItem(
                id: "30000000-0000-0000-0000-000000000002",
                name: "Unknown Category Piece",
                categoryRawValue: "headwear",
                createdAt: localDate(year: 2_026, month: 2, day: 1),
                photoData: Data([0x0A, 0x0B]),
                updatedAt: localDate(year: 2_026, month: 2, day: 3)
            )
        ]
    )
}

@MainActor
private func makeMergeUpdatesFixture(
    context: ModelContext
) throws -> (
    localItem: Item,
    snapshot: StallyBackupSnapshot
) {
    let localItem = try makeStoredItem(
        name: "Old Name",
        category: .other,
        createdAt: localDate(year: 2_026, month: 1, day: 1),
        note: "Old note",
        updatedAt: localDate(year: 2_026, month: 1, day: 10),
        id: "50000000-0000-0000-0000-000000000001"
    )
    let localMark = try makeStoredMark(
        id: "60000000-0000-0000-0000-000000000001",
        item: localItem,
        day: localDate(year: 2_026, month: 2, day: 1)
    )
    context.insert(localItem)
    context.insert(localMark)
    try context.save()

    let snapshot = makeBackupSnapshot(
        exportedAt: localDate(year: 2_026, month: 3, day: 8),
        items: [
            try makeBackupItem(
                id: "50000000-0000-0000-0000-000000000001",
                name: "Imported Name",
                categoryRawValue: ItemCategory.clothing.rawValue,
                createdAt: localDate(year: 2_025, month: 12, day: 20),
                photoData: Data([0x01]),
                note: "Imported note",
                updatedAt: localDate(year: 2_026, month: 2, day: 20),
                archivedAt: localDate(year: 2_026, month: 2, day: 25),
                marks: [
                    try makeBackupMark(
                        id: "60000000-0000-0000-0000-000000000002",
                        day: localDate(year: 2_026, month: 2, day: 1)
                    ),
                    try makeBackupMark(
                        id: "60000000-0000-0000-0000-000000000003",
                        day: localDate(year: 2_026, month: 2, day: 4)
                    )
                ]
            )
        ]
    )

    return (
        localItem: localItem,
        snapshot: snapshot
    )
}
