//
//  BackupOperationsImportIntegrityTests.swift
//  StallyLibraryTests
//
//  Created by Codex on 2026/07/12.
//

import Foundation
@testable import StallyLibrary
import SwiftData
import Testing

extension SwiftDataOperationsTests {
    @Suite
    struct BackupOperationsImportIntegrityTests {
        // swiftlint:disable:next nesting
        private enum Fixtures {
            static var today: LocalDay {
                guard let day = LocalDay(year: 2_026, month: 6, day: 26) else {
                    preconditionFailure("Invalid fixture day")
                }

                return day
            }

            static func timestamp(offset: Int = 0) -> Date {
                .init(timeIntervalSinceReferenceDate: TimeInterval(offset))
            }
        }

        @Test
        func `duplicate local days fail closed for preview merge and replace`() throws {
            let context = try makeContext()
            _ = try createItem(context: context, name: "Local Item")
            let backupItemID = UUID()
            let firstMark = BackupMark(
                id: UUID(),
                day: Fixtures.today,
                createdAt: Fixtures.timestamp()
            )
            let secondMark = BackupMark(
                id: UUID(),
                day: Fixtures.today,
                createdAt: Fixtures.timestamp(offset: 1)
            )
            let snapshot = BackupSnapshot(
                exportedAt: Fixtures.timestamp(),
                items: [
                    backupItem(
                        id: backupItemID,
                        marks: [firstMark, secondMark]
                    )
                ]
            )
            let expectedPreview = BackupOperations.preview(
                snapshot: snapshot,
                currentItems: try fetchItems(context)
            )

            #expect(!expectedPreview.canImport)
            #expect(expectedPreview.marksAddedCount == 0)
            #expect(expectedPreview.validationIssues.map(\.kind) == [.duplicateMarkDay])
            #expect(throws: BackupError.validationFailed(expectedPreview)) {
                try BackupOperations.mergeIntoLibrary(
                    snapshot: snapshot,
                    context: context
                )
            }
            #expect(throws: BackupError.validationFailed(expectedPreview)) {
                try BackupOperations.replaceLibrary(
                    snapshot: snapshot,
                    context: context
                )
            }

            let items = try fetchItems(context)
            #expect(items.map(\.name) == ["Local Item"])
            #expect(!items.map(\.uuid).contains(backupItemID))
        }

        @Test
        func `duplicate current item identifiers fail closed without trapping`() throws {
            let context = try makeContext()
            let firstItem = try createItem(context: context, name: "First Local Item")
            let secondItem = try createItem(context: context, name: "Second Local Item")
            secondItem.uuid = firstItem.uuid
            try context.save()
            let backupItemID = UUID()
            let snapshot = BackupSnapshot(
                exportedAt: Fixtures.timestamp(),
                items: [backupItem(id: backupItemID, marks: [])]
            )
            let expectedPreview = BackupOperations.preview(
                snapshot: snapshot,
                currentItems: try fetchItems(context)
            )

            #expect(!expectedPreview.canImport)
            #expect(expectedPreview.marksAddedCount == 0)
            #expect(expectedPreview.validationIssues.map(\.kind) == [.duplicateCurrentItemID])
            #expect(throws: BackupError.validationFailed(expectedPreview)) {
                try BackupOperations.mergeIntoLibrary(
                    snapshot: snapshot,
                    context: context
                )
            }
            #expect(throws: BackupError.validationFailed(expectedPreview)) {
                try BackupOperations.replaceLibrary(
                    snapshot: snapshot,
                    context: context
                )
            }

            let items = try fetchItems(context)
            #expect(items.count == 2)
            #expect(!items.map(\.uuid).contains(backupItemID))
        }

        private func makeContext() throws -> ModelContext {
            .init(try StallyModelContainerFactory.inMemory())
        }

        private func fetchItems(_ context: ModelContext) throws -> [Item] {
            try context.fetch(.init())
        }

        private func createItem(context: ModelContext, name: String) throws -> Item {
            try ItemOperations.create(
                context: context,
                input: .init(name: name, category: .other),
                createdAt: Fixtures.timestamp()
            )
        }

        private func backupItem(id: UUID, marks: [BackupMark]) -> BackupItem {
            .init(
                id: id,
                name: "Canvas Tote",
                categoryRawValue: ItemCategory.bags.rawValue,
                note: "",
                photoData: nil,
                createdAt: Fixtures.timestamp(),
                archivedAt: nil,
                marks: marks
            )
        }
    }
}
