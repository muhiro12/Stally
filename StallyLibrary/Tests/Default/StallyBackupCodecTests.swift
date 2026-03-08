import Foundation
import SwiftData
@testable import StallyLibrary
import XCTest

final class StallyBackupCodecTests: XCTestCase {
    @MainActor
    func testExportRoundTripsItemsMarksAndArchiveState() throws {
        let context = testContext()
        let firstItemID = try XCTUnwrap(
            UUID(uuidString: "8B30C6DE-228B-4C58-B6D8-5C4DA7D57A31")
        )
        let firstMarkID = try XCTUnwrap(
            UUID(uuidString: "9BAEBF3B-0CAB-44B5-81EC-93838525E4A0")
        )
        let secondMarkID = try XCTUnwrap(
            UUID(uuidString: "1A6D0D7D-DFBC-42D4-8D73-A7D7FC1C8259")
        )
        let archivedItemID = try XCTUnwrap(
            UUID(uuidString: "4E886133-4A69-4831-AC93-6E572653ED99")
        )
        let exportDate = localDate(year: 2026, month: 3, day: 8, hour: 8)
        let firstCreatedAt = localDate(year: 2025, month: 12, day: 15)
        let firstUpdatedAt = localDate(year: 2026, month: 2, day: 28)
        let archiveCreatedAt = localDate(year: 2025, month: 10, day: 2)
        let archiveUpdatedAt = localDate(year: 2026, month: 1, day: 12)
        let archivedAt = localDate(year: 2026, month: 1, day: 10)

        let firstItem = Item(
            id: firstItemID,
            name: "Field Jacket",
            category: .clothing,
            photoData: Data([0x01, 0x02, 0x03]),
            note: "Lightweight layer.",
            createdAt: firstCreatedAt,
            updatedAt: firstUpdatedAt
        )
        let firstMark = Mark(
            id: firstMarkID,
            item: firstItem,
            day: DayStamp.storageDate(from: localDate(year: 2026, month: 1, day: 20)),
            createdAt: localDate(year: 2026, month: 1, day: 20, hour: 18)
        )
        let secondMark = Mark(
            id: secondMarkID,
            item: firstItem,
            day: DayStamp.storageDate(from: localDate(year: 2026, month: 2, day: 27)),
            createdAt: localDate(year: 2026, month: 2, day: 27, hour: 11)
        )
        _ = secondMark
        _ = firstMark

        let archivedItem = Item(
            id: archivedItemID,
            name: "Travel Tote",
            category: .bags,
            photoData: nil,
            note: nil,
            createdAt: archiveCreatedAt,
            updatedAt: archiveUpdatedAt,
            archivedAt: archivedAt
        )
        context.insert(firstItem)
        context.insert(archivedItem)
        context.insert(firstMark)
        context.insert(secondMark)
        try context.save()

        let items = try context.fetch(FetchDescriptor<Item>())

        let data = try StallyBackupCodec.exportData(
            from: items,
            exportedAt: exportDate
        )
        let snapshot = try StallyBackupCodec.decode(data)

        XCTAssertEqual(snapshot.schemaVersion, StallyBackupSnapshot.currentSchemaVersion)
        XCTAssertEqual(snapshot.exportedAt, exportDate)
        XCTAssertEqual(snapshot.items.count, 2)
        XCTAssertEqual(snapshot.items[0].id, archivedItemID)
        XCTAssertEqual(snapshot.items[1].id, firstItemID)
        XCTAssertEqual(snapshot.items[1].marks.map(\.id), [firstMarkID, secondMarkID])
        XCTAssertEqual(snapshot.items[1].photoData, Data([0x01, 0x02, 0x03]))
        XCTAssertEqual(snapshot.items[0].archivedAt, archivedAt)
    }

    func testEncodeSortsItemsAndMarksDeterministically() throws {
        let firstItem = StallyBackupItem(
            id: try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-0000000000B2")),
            name: "Second",
            categoryRawValue: ItemCategory.other.rawValue,
            photoData: nil,
            note: nil,
            createdAt: localDate(year: 2026, month: 3, day: 2),
            updatedAt: localDate(year: 2026, month: 3, day: 4),
            archivedAt: nil,
            marks: [
                .init(
                    id: try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-0000000000D2")),
                    day: localDate(year: 2026, month: 3, day: 5),
                    createdAt: localDate(year: 2026, month: 3, day: 5, hour: 18)
                ),
                .init(
                    id: try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-0000000000D1")),
                    day: localDate(year: 2026, month: 3, day: 1),
                    createdAt: localDate(year: 2026, month: 3, day: 1, hour: 9)
                )
            ]
        )
        let secondItem = StallyBackupItem(
            id: try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")),
            name: "First",
            categoryRawValue: ItemCategory.bags.rawValue,
            photoData: nil,
            note: nil,
            createdAt: localDate(year: 2026, month: 3, day: 1),
            updatedAt: localDate(year: 2026, month: 3, day: 1),
            archivedAt: nil,
            marks: []
        )
        let snapshot = StallyBackupSnapshot(
            exportedAt: localDate(year: 2026, month: 3, day: 8),
            items: [firstItem, secondItem]
        )

        XCTAssertEqual(snapshot.items.map(\.name), ["First", "Second"])
        XCTAssertEqual(snapshot.items[1].marks.map { $0.id.uuidString.lowercased() }, [
            "00000000-0000-0000-0000-0000000000d1",
            "00000000-0000-0000-0000-0000000000d2"
        ])

        let data = try StallyBackupCodec.encode(snapshot)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))

        XCTAssertTrue(json.contains("\"schemaVersion\" : 1"))
        XCTAssertLessThan(
            json.range(of: "\"First\"")?.lowerBound ?? json.endIndex,
            json.range(of: "\"Second\"")?.lowerBound ?? json.endIndex
        )
    }
}
