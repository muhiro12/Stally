import Foundation
import SwiftData
@testable import Stally
@testable import StallyLibrary
import XCTest

final class StallyBackupWorkflowTests: XCTestCase {
    @MainActor
    func testPrepareExportBuildsDocumentAndFilename() throws {
        let context = testContext()
        let item = try createTestItem(
            context: context,
            name: "Field Notes",
            category: .other
        )
        try markTestItem(
            context: context,
            item: item,
            on: localDate(year: 2026, month: 3, day: 22)
        )

        let preparation = StallyBackupWorkflow.prepareExport(
            items: [item]
        )

        XCTAssertEqual(preparation.snapshot.items.count, 1)
        XCTAssertEqual(preparation.document.snapshot.items.count, 1)
        XCTAssertTrue(
            preparation.filename.hasPrefix("stally-backup-")
        )
    }

    @MainActor
    func testMakeImportPreviewLoadsBackupAnalysis() throws {
        let context = testContext()
        let item = try createTestItem(
            context: context,
            name: "Daily Bottle",
            category: .other
        )
        let preparation = StallyBackupWorkflow.prepareExport(
            items: [item]
        )
        let url = try makeBackupFileURL(
            snapshot: preparation.snapshot,
            filename: "preview.stallybackup"
        )

        let preview = try StallyBackupWorkflow.makeImportPreview(
            from: url,
            existingItemIDs: []
        )

        XCTAssertEqual(
            preview.analysis.summary.totalItems,
            1
        )
        XCTAssertEqual(
            preview.analysis.summary.newItems,
            1
        )
        XCTAssertEqual(
            preview.sourceURL.lastPathComponent,
            "preview.stallybackup"
        )
    }

    @MainActor
    func testMakeImportPreviewClassifiesDecodeFailure() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("stallybackup")
        try Data("not-json".utf8).write(to: url)

        defer {
            try? FileManager.default.removeItem(at: url)
        }

        XCTAssertThrowsError(
            try StallyBackupWorkflow.makeImportPreview(
                from: url,
                existingItemIDs: []
            )
        ) { error in
            let transferError = error as? StallyTransferOperationError

            XCTAssertEqual(
                transferError?.operation,
                .importPreview
            )
            XCTAssertEqual(
                transferError?.phase,
                .decode
            )
        }
    }

    @MainActor
    func testMergeImportClassifiesValidationFailureAsPreflight() throws {
        let context = testContext()
        let snapshot = makeInvalidSnapshot(
            duplicatedItemID: UUID()
        )
        let preview = makePreview(snapshot: snapshot)

        XCTAssertThrowsError(
            try StallyBackupWorkflow.mergeImport(
                context: context,
                preview: preview
            )
        ) { error in
            let transferError = error as? StallyTransferOperationError

            XCTAssertEqual(
                transferError?.operation,
                .mergeImport
            )
            XCTAssertEqual(
                transferError?.phase,
                .preflight
            )
        }
    }

    @MainActor
    func testReplaceImportClassifiesValidationFailureAsPreflight() throws {
        let context = testContext()
        let snapshot = makeInvalidSnapshot(
            duplicatedItemID: UUID()
        )
        let preview = makePreview(snapshot: snapshot)

        XCTAssertThrowsError(
            try StallyBackupWorkflow.replaceImport(
                context: context,
                preview: preview
            )
        ) { error in
            let transferError = error as? StallyTransferOperationError

            XCTAssertEqual(
                transferError?.operation,
                .replaceImport
            )
            XCTAssertEqual(
                transferError?.phase,
                .preflight
            )
        }
    }

    @MainActor
    func testRecordImportFailurePreservesPreviewForBlockingFailure() {
        let preview = makePreview(
            snapshot: makeInvalidSnapshot(
                duplicatedItemID: UUID()
            )
        )
        var state = StallyBackupCenterState()
        state.recordImportPreview(preview)

        let error = StallyTransferOperationError(
            operation: .mergeImport,
            phase: .mutation,
            underlyingError: CocoaError(.fileReadUnknown),
            fallbackDescription: "fallback"
        )

        state.recordImportFailure(
            error,
            operation: .mergeImport,
            phase: .mutation,
            fallback: "fallback",
            preservePreview: true
        )

        XCTAssertEqual(
            state.importPreview?.sourceName,
            preview.sourceName
        )
        XCTAssertEqual(
            state.importStatus?.failure?.operation,
            .mergeImport
        )
    }

    @MainActor
    func testDeleteAllItemsRemovesPersistedItems() throws {
        let context = testContext()
        _ = try createTestItem(
            context: context,
            name: "Camera Strap",
            category: .bags
        )

        try StallyBackupWorkflow.deleteAllItems(
            context: context
        )

        XCTAssertTrue(
            try fetchItems(context: context).isEmpty
        )
    }
}

private extension StallyBackupWorkflowTests {
    @MainActor
    func makeBackupFileURL(
        snapshot: StallyBackupSnapshot,
        filename: String
    ) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let url = directory.appendingPathComponent(filename)

        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        try StallyBackupFileAdapter.encodeData(
            for: snapshot
        ).write(to: url)

        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }

        return url
    }

    @MainActor
    func makeInvalidSnapshot(
        duplicatedItemID: UUID
    ) -> StallyBackupSnapshot {
        .init(
            exportedAt: .now,
            items: [
                .init(
                    id: duplicatedItemID,
                    name: "Weekender",
                    categoryRawValue: ItemCategory.bags.rawValue,
                    photoData: nil,
                    note: nil,
                    createdAt: .now,
                    updatedAt: .now,
                    archivedAt: nil,
                    marks: []
                ),
                .init(
                    id: duplicatedItemID,
                    name: "Spare Weekender",
                    categoryRawValue: ItemCategory.bags.rawValue,
                    photoData: nil,
                    note: nil,
                    createdAt: .now,
                    updatedAt: .now,
                    archivedAt: nil,
                    marks: []
                )
            ]
        )
    }

    @MainActor
    func makePreview(
        snapshot: StallyBackupSnapshot
    ) -> StallyBackupCenterState.ImportPreview {
        .init(
            sourceURL: FileManager.default.temporaryDirectory
                .appendingPathComponent("invalid.stallybackup"),
            analysis: StallyBackupImportAnalyzer.analyze(
                snapshot: snapshot,
                existingItemIDs: []
            )
        )
    }
}
