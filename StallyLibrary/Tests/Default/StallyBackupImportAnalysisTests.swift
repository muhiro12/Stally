import Foundation
@testable import StallyLibrary
import XCTest

final class StallyBackupImportAnalysisTests: XCTestCase {
    func testAnalyzeFlagsUnsupportedSchemaAndDuplicateIdentifiers() throws {
        let snapshot = makeBackupSnapshot(
            exportedAt: localDate(year: 2_026, month: 3, day: 8),
            items: [
                try makeBackupItem(
                    id: "11111111-1111-1111-1111-111111111111",
                    name: "Archive Coat",
                    categoryRawValue: ItemCategory.clothing.rawValue,
                    createdAt: localDate(year: 2_026, month: 1, day: 1),
                    updatedAt: localDate(year: 2_026, month: 2, day: 1),
                    marks: [
                        try makeBackupMark(
                            id: "22222222-2222-2222-2222-222222222222",
                            day: localDate(year: 2_026, month: 2, day: 1)
                        )
                    ]
                ),
                try makeBackupItem(
                    id: "11111111-1111-1111-1111-111111111111",
                    name: "Archive Bag",
                    categoryRawValue: ItemCategory.bags.rawValue,
                    createdAt: localDate(year: 2_026, month: 1, day: 2),
                    updatedAt: localDate(year: 2_026, month: 2, day: 2),
                    archivedAt: localDate(year: 2_026, month: 2, day: 3),
                    marks: [
                        try makeBackupMark(
                            id: "22222222-2222-2222-2222-222222222222",
                            day: localDate(year: 2_026, month: 2, day: 2)
                        )
                    ]
                )
            ],
            schemaVersion: 99,
            )

        let analysis = StallyBackupImportAnalyzer.analyze(snapshot: snapshot)

        XCTAssertFalse(analysis.canImport)
        XCTAssertEqual(analysis.summary.totalItems, 2)
        XCTAssertEqual(analysis.summary.archivedItems, 1)
        XCTAssertEqual(analysis.summary.totalMarks, 2)
        XCTAssertEqual(
            analysis.errors.map(\.code),
            [
                .duplicateItemID,
                .duplicateMarkID,
                .unsupportedSchemaVersion
            ]
        )
    }

    func testAnalyzeCountsExistingItemsAndWarnsUnknownCategories() throws {
        let snapshot = makeBackupSnapshot(
            exportedAt: localDate(year: 2_026, month: 3, day: 8),
            items: [
                try makeBackupItem(
                    id: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA",
                    name: "Known Item",
                    categoryRawValue: ItemCategory.shoes.rawValue,
                    createdAt: localDate(year: 2_026, month: 1, day: 3),
                    note: "Already in the library.",
                    updatedAt: localDate(year: 2_026, month: 2, day: 3)
                ),
                try makeBackupItem(
                    id: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB",
                    name: "Unknown Category Item",
                    categoryRawValue: "headwear",
                    createdAt: localDate(year: 2_026, month: 1, day: 4),
                    updatedAt: localDate(year: 2_026, month: 2, day: 4),
                    archivedAt: localDate(year: 2_026, month: 2, day: 5),
                    marks: [
                        try makeBackupMark(
                            id: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC",
                            day: localDate(year: 2_026, month: 2, day: 1)
                        )
                    ]
                )
            ]
        )

        let analysis = StallyBackupImportAnalyzer.analyze(
            snapshot: snapshot,
            existingItemIDs: [try testUUID("AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")]
        )

        XCTAssertTrue(analysis.canImport)
        XCTAssertEqual(analysis.summary.totalItems, 2)
        XCTAssertEqual(analysis.summary.archivedItems, 1)
        XCTAssertEqual(analysis.summary.totalMarks, 1)
        XCTAssertEqual(analysis.summary.existingItems, 1)
        XCTAssertEqual(analysis.summary.newItems, 1)
        XCTAssertEqual(analysis.warnings.count, 1)
        XCTAssertEqual(analysis.warnings.first?.code, .unknownCategory)
        XCTAssertEqual(analysis.warnings.first?.categoryRawValue, "headwear")
        XCTAssertEqual(snapshot.items[1].category, .other)
        XCTAssertFalse(snapshot.items[1].hasKnownCategory)
        XCTAssertEqual(snapshot.items[1].lastMarkedAt, localDate(year: 2_026, month: 2, day: 1))
    }
}
