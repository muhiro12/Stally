//
//  BackupOperationsSafetyTests.swift
//  StallyLibraryTests
//
//  Created by Codex on 2026/06/26.
//

import Foundation
@testable import StallyLibrary
import SwiftData
import Testing

extension SwiftDataOperationsTests {
    @Suite
    struct BackupOperationsSafetyTests {
        // swiftlint:disable:next nesting
        private enum Fixtures {
            static var today: LocalDay {
                day(offset: 0)
            }

            static func day(offset: Int) -> LocalDay {
                guard let baseDay = LocalDay(year: 2_026, month: 6, day: 26),
                      let resolvedDay = baseDay.adding(days: offset) else {
                    preconditionFailure("Invalid fixture base day")
                }

                return resolvedDay
            }

            static func timestamp(offset: Int = 0) -> Date {
                .init(timeIntervalSinceReferenceDate: TimeInterval(offset))
            }
        }

        @Test
        func `preview surfaces validation issues before import`() {
            let duplicateItemID = UUID()
            let duplicateMarkID = UUID()
            let snapshot = validationSnapshot(
                duplicateItemID: duplicateItemID,
                duplicateMarkID: duplicateMarkID
            )

            let preview = BackupOperations.preview(
                snapshot: snapshot,
                currentItems: []
            )

            #expect(!preview.canImport)
            #expect(preview.skippedItemCount == 2)
            #expect(
                preview.validationIssues.map(\.kind) == [
                    .unsupportedSchemaVersion,
                    .duplicateItemID,
                    .duplicateMarkID,
                    .itemNameRequired,
                    .unknownCategory
                ]
            )
        }

        @Test
        func `replace rejects nameless backup items before deleting local library`() throws {
            let context = try makeContext()
            _ = try createItem(context: context, name: "Local Item")
            let snapshot = BackupSnapshot(
                exportedAt: Fixtures.timestamp(),
                items: [
                    .init(
                        id: UUID(),
                        name: "   ",
                        categoryRawValue: ItemCategory.other.rawValue,
                        note: "",
                        photoData: nil,
                        createdAt: Fixtures.timestamp(),
                        archivedAt: nil,
                        marks: []
                    )
                ]
            )
            let expectedPreview = BackupOperations.preview(
                snapshot: snapshot,
                currentItems: try fetchItems(context)
            )

            #expect(throws: BackupError.validationFailed(expectedPreview)) {
                try BackupOperations.replaceLibrary(
                    snapshot: snapshot,
                    context: context
                )
            }

            let items = try fetchItems(context)
            #expect(items.map(\.name) == ["Local Item"])
        }

        @Test
        func `replace rejects unsupported backup data before deleting local library`() throws {
            let context = try makeContext()
            _ = try createItem(context: context, name: "Local Item")
            let unsupportedData = Data(#"{"schemaVersion":1}"#.utf8)
            let expectedPreview = BackupOperations.preview(
                data: unsupportedData,
                currentItems: try fetchItems(context)
            )

            #expect(throws: BackupError.validationFailed(expectedPreview)) {
                try BackupOperations.replaceLibrary(
                    data: unsupportedData,
                    context: context
                )
            }

            #expect(try fetchItems(context).map(\.name) == ["Local Item"])
        }

        @Test
        func `delete everything removes items and marks`() throws {
            let context = try makeContext()
            let firstItem = try createItem(context: context, name: "Black Wool Coat")
            let secondItem = try createItem(context: context, name: "White Everyday Sneakers")
            try mark(firstItem, offsets: [0], context: context)
            try mark(secondItem, offsets: [-1], context: context)
            let orphanMark = ItemMark(
                day: Fixtures.day(offset: -2),
                createdAt: Fixtures.timestamp(offset: -2),
                item: nil,
                uuid: .init()
            )
            context.insert(orphanMark)
            try context.save()

            let result = try BackupOperations.deleteEverything(context: context)

            #expect(result.deletedItemCount == 2)
            #expect(result.deletedMarkCount == 3)
            #expect(try fetchItems(context).isEmpty)
            #expect(try fetchMarks(context).isEmpty)
        }

        private func makeContext() throws -> ModelContext {
            .init(try StallyModelContainerFactory.inMemory())
        }

        private func fetchItems(_ context: ModelContext) throws -> [Item] {
            try context.fetch(.init())
        }

        private func fetchMarks(_ context: ModelContext) throws -> [ItemMark] {
            try context.fetch(.init())
        }

        private func createItem(
            context: ModelContext,
            name: String
        ) throws -> Item {
            try ItemOperations.create(
                context: context,
                input: .init(name: name, category: .other),
                createdAt: Fixtures.timestamp()
            )
        }

        private func mark(
            _ item: Item,
            offsets: [Int],
            context: ModelContext
        ) throws {
            for offset in offsets {
                try ItemOperations.mark(
                    item,
                    on: Fixtures.day(offset: offset),
                    today: Fixtures.today,
                    context: context
                )
            }
        }

        private func validationSnapshot(
            duplicateItemID: UUID,
            duplicateMarkID: UUID
        ) -> BackupSnapshot {
            .init(
                exportedAt: Fixtures.timestamp(),
                items: [
                    validBackupItem(itemID: duplicateItemID, markID: duplicateMarkID),
                    unknownCategoryBackupItem(itemID: duplicateItemID, markID: duplicateMarkID),
                    namelessBackupItem()
                ],
                schemaVersion: BackupSnapshot.currentSchemaVersion + 1
            )
        }

        private func validBackupItem(itemID: UUID, markID: UUID) -> BackupItem {
            .init(
                id: itemID,
                name: "Canvas Tote",
                categoryRawValue: ItemCategory.bags.rawValue,
                note: "",
                photoData: nil,
                createdAt: Fixtures.timestamp(),
                archivedAt: nil,
                marks: [
                    .init(id: markID, day: Fixtures.today, createdAt: Fixtures.timestamp())
                ]
            )
        }

        private func unknownCategoryBackupItem(itemID: UUID, markID: UUID) -> BackupItem {
            .init(
                id: itemID,
                name: "Unknown Category Item",
                categoryRawValue: "Gear",
                note: "",
                photoData: nil,
                createdAt: Fixtures.timestamp(),
                archivedAt: nil,
                marks: [
                    .init(
                        id: markID,
                        day: Fixtures.day(offset: -1),
                        createdAt: Fixtures.timestamp()
                    )
                ]
            )
        }

        private func namelessBackupItem() -> BackupItem {
            .init(
                id: UUID(),
                name: "   ",
                categoryRawValue: ItemCategory.other.rawValue,
                note: "",
                photoData: nil,
                createdAt: Fixtures.timestamp(),
                archivedAt: nil,
                marks: []
            )
        }
    }
}
