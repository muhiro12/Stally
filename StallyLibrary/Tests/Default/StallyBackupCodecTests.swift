import Foundation
import SwiftData
@testable import StallyLibrary
import XCTest

final class StallyBackupCodecTests: XCTestCase {
    @MainActor
    func testExportRoundTripsItemsMarksAndArchiveState() throws {
        let context = testContext()
        let fixture = try makeExportRoundTripFixture(context: context)
        let data = try StallyBackupCodec.exportData(
            from: fixture.items,
            exportedAt: fixture.exportDate
        )
        let snapshot = try StallyBackupCodec.decode(data)

        XCTAssertEqual(snapshot.schemaVersion, StallyBackupSnapshot.currentSchemaVersion)
        XCTAssertEqual(snapshot.exportedAt, fixture.exportDate)
        XCTAssertEqual(snapshot.items.count, 2)
        XCTAssertEqual(snapshot.items[0].id, try testUUID("4E886133-4A69-4831-AC93-6E572653ED99"))
        XCTAssertEqual(snapshot.items[1].id, try testUUID("8B30C6DE-228B-4C58-B6D8-5C4DA7D57A31"))
        XCTAssertEqual(snapshot.items[1].marks.map(\.id), [
            try testUUID("9BAEBF3B-0CAB-44B5-81EC-93838525E4A0"),
            try testUUID("1A6D0D7D-DFBC-42D4-8D73-A7D7FC1C8259")
        ])
        XCTAssertEqual(snapshot.items[1].photoData, Data([0x01, 0x02, 0x03]))
        XCTAssertEqual(
            snapshot.items[0].archivedAt,
            localDate(year: 2_026, month: 1, day: 10)
        )
    }

    func testEncodeSortsItemsAndMarksDeterministically() throws {
        let firstItem = try makeBackupItem(
            id: "00000000-0000-0000-0000-0000000000B2",
            name: "Second",
            categoryRawValue: ItemCategory.other.rawValue,
            createdAt: localDate(year: 2_026, month: 3, day: 2),
            updatedAt: localDate(year: 2_026, month: 3, day: 4),
            marks: [
                try makeBackupMark(
                    id: "00000000-0000-0000-0000-0000000000D2",
                    day: localDate(year: 2_026, month: 3, day: 5),
                    createdAt: localDate(year: 2_026, month: 3, day: 5, hour: 18)
                ),
                try makeBackupMark(
                    id: "00000000-0000-0000-0000-0000000000D1",
                    day: localDate(year: 2_026, month: 3, day: 1),
                    createdAt: localDate(year: 2_026, month: 3, day: 1, hour: 9)
                )
            ]
        )
        let secondItem = try makeBackupItem(
            id: "00000000-0000-0000-0000-0000000000A1",
            name: "First",
            categoryRawValue: ItemCategory.bags.rawValue,
            createdAt: localDate(year: 2_026, month: 3, day: 1)
        )
        let snapshot = makeBackupSnapshot(
            exportedAt: localDate(year: 2_026, month: 3, day: 8),
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

@MainActor
private func makeExportRoundTripFixture(
    context: ModelContext
) throws -> (
    exportDate: Date,
    items: [Item]
) {
    let exportDate = localDate(year: 2_026, month: 3, day: 8, hour: 8)
    let firstItem = try makeStoredItem(
        name: "Field Jacket",
        category: .clothing,
        createdAt: localDate(year: 2_025, month: 12, day: 15),
        photoData: Data([0x01, 0x02, 0x03]),
        note: "Lightweight layer.",
        updatedAt: localDate(year: 2_026, month: 2, day: 28),
        id: "8B30C6DE-228B-4C58-B6D8-5C4DA7D57A31"
    )
    let firstMark = try makeStoredMark(
        id: "9BAEBF3B-0CAB-44B5-81EC-93838525E4A0",
        item: firstItem,
        day: localDate(year: 2_026, month: 1, day: 20),
        createdAt: localDate(year: 2_026, month: 1, day: 20, hour: 18)
    )
    let secondMark = try makeStoredMark(
        id: "1A6D0D7D-DFBC-42D4-8D73-A7D7FC1C8259",
        item: firstItem,
        day: localDate(year: 2_026, month: 2, day: 27),
        createdAt: localDate(year: 2_026, month: 2, day: 27, hour: 11)
    )
    let archivedItem = try makeStoredItem(
        name: "Travel Tote",
        category: .bags,
        createdAt: localDate(year: 2_025, month: 10, day: 2),
        updatedAt: localDate(year: 2_026, month: 1, day: 12),
        archivedAt: localDate(year: 2_026, month: 1, day: 10),
        id: "4E886133-4A69-4831-AC93-6E572653ED99"
    )
    context.insert(firstItem)
    context.insert(archivedItem)
    context.insert(firstMark)
    context.insert(secondMark)
    try context.save()

    return (
        exportDate: exportDate,
        items: try context.fetch(FetchDescriptor<Item>())
    )
}
