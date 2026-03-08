import Foundation
@testable import StallyLibrary
import XCTest

final class StallyBackupImportAnalysisTests: XCTestCase {
    func testAnalyzeFlagsUnsupportedSchemaAndDuplicateIdentifiers() throws {
        let duplicateItemID = try XCTUnwrap(
            UUID(uuidString: "11111111-1111-1111-1111-111111111111")
        )
        let duplicateMarkID = try XCTUnwrap(
            UUID(uuidString: "22222222-2222-2222-2222-222222222222")
        )
        let snapshot = StallyBackupSnapshot(
            schemaVersion: 99,
            exportedAt: localDate(year: 2026, month: 3, day: 8),
            items: [
                .init(
                    id: duplicateItemID,
                    name: "Archive Coat",
                    categoryRawValue: ItemCategory.clothing.rawValue,
                    photoData: nil,
                    note: nil,
                    createdAt: localDate(year: 2026, month: 1, day: 1),
                    updatedAt: localDate(year: 2026, month: 2, day: 1),
                    archivedAt: nil,
                    marks: [
                        .init(
                            id: duplicateMarkID,
                            day: localDate(year: 2026, month: 2, day: 1),
                            createdAt: localDate(year: 2026, month: 2, day: 1)
                        )
                    ]
                ),
                .init(
                    id: duplicateItemID,
                    name: "Archive Bag",
                    categoryRawValue: ItemCategory.bags.rawValue,
                    photoData: nil,
                    note: nil,
                    createdAt: localDate(year: 2026, month: 1, day: 2),
                    updatedAt: localDate(year: 2026, month: 2, day: 2),
                    archivedAt: localDate(year: 2026, month: 2, day: 3),
                    marks: [
                        .init(
                            id: duplicateMarkID,
                            day: localDate(year: 2026, month: 2, day: 2),
                            createdAt: localDate(year: 2026, month: 2, day: 2)
                        )
                    ]
                )
            ]
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
        let existingItemID = try XCTUnwrap(
            UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")
        )
        let snapshot = StallyBackupSnapshot(
            exportedAt: localDate(year: 2026, month: 3, day: 8),
            items: [
                .init(
                    id: existingItemID,
                    name: "Known Item",
                    categoryRawValue: ItemCategory.shoes.rawValue,
                    photoData: nil,
                    note: "Already in the library.",
                    createdAt: localDate(year: 2026, month: 1, day: 3),
                    updatedAt: localDate(year: 2026, month: 2, day: 3),
                    archivedAt: nil,
                    marks: []
                ),
                .init(
                    id: try XCTUnwrap(UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")),
                    name: "Unknown Category Item",
                    categoryRawValue: "headwear",
                    photoData: nil,
                    note: nil,
                    createdAt: localDate(year: 2026, month: 1, day: 4),
                    updatedAt: localDate(year: 2026, month: 2, day: 4),
                    archivedAt: localDate(year: 2026, month: 2, day: 5),
                    marks: [
                        .init(
                            id: try XCTUnwrap(UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")),
                            day: localDate(year: 2026, month: 2, day: 1),
                            createdAt: localDate(year: 2026, month: 2, day: 1)
                        )
                    ]
                )
            ]
        )

        let analysis = StallyBackupImportAnalyzer.analyze(
            snapshot: snapshot,
            existingItemIDs: [existingItemID]
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
        XCTAssertEqual(snapshot.items[1].lastMarkedAt, localDate(year: 2026, month: 2, day: 1))
    }
}
