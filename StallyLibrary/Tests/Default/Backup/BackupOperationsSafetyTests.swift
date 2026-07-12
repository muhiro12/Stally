//
//  BackupOperationsSafetyTests.swift
//  StallyLibraryTests
//
//  Created by Codex on 2026/06/26.
//

import Foundation
import StallyLibrary
import SwiftData
import Testing

extension SwiftDataOperationsTests {
    @Suite
    struct BackupOperationsSafetyTests {
        // swiftlint:disable:next nesting
        private enum Fixtures {
            static var calendar: Calendar {
                var configuredCalendar = Calendar(identifier: .gregorian)
                configuredCalendar.timeZone = TimeZone(secondsFromGMT: 0) ?? configuredCalendar.timeZone
                return configuredCalendar
            }

            static var today: Date {
                day(offset: 0)
            }

            private static var baseDay: Date {
                let components = DateComponents(
                    calendar: calendar,
                    timeZone: calendar.timeZone,
                    year: 2_026,
                    month: 6,
                    day: 26
                )

                guard let date = components.date else {
                    preconditionFailure("Invalid fixture base day")
                }

                return date
            }

            static func day(offset: Int) -> Date {
                guard let date = calendar.date(byAdding: .day, value: offset, to: baseDay) else {
                    preconditionFailure("Invalid fixture day offset: \(offset)")
                }

                return date
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
                currentItems: [],
                calendar: Fixtures.calendar
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
                exportedAt: Fixtures.today,
                items: [
                    .init(
                        id: UUID(),
                        name: "   ",
                        categoryRawValue: ItemCategory.other.rawValue,
                        note: "",
                        photoData: nil,
                        createdAt: Fixtures.today,
                        archivedAt: nil,
                        marks: []
                    )
                ]
            )
            let expectedPreview = BackupOperations.preview(
                snapshot: snapshot,
                currentItems: try fetchItems(context),
                calendar: Fixtures.calendar
            )

            #expect(throws: BackupError.validationFailed(expectedPreview)) {
                try BackupOperations.replaceLibrary(
                    snapshot: snapshot,
                    context: context,
                    calendar: Fixtures.calendar
                )
            }

            let items = try fetchItems(context)
            #expect(items.map(\.name) == ["Local Item"])
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
                createdAt: Fixtures.day(offset: -2)
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
                createdAt: Fixtures.today
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
                    context: context,
                    calendar: Fixtures.calendar
                )
            }
        }

        private func validationSnapshot(
            duplicateItemID: UUID,
            duplicateMarkID: UUID
        ) -> BackupSnapshot {
            .init(
                exportedAt: Fixtures.today,
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
                createdAt: Fixtures.today,
                archivedAt: nil,
                marks: [
                    .init(id: markID, day: Fixtures.today, createdAt: Fixtures.today)
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
                createdAt: Fixtures.today,
                archivedAt: nil,
                marks: [
                    .init(id: markID, day: Fixtures.day(offset: -1), createdAt: Fixtures.today)
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
                createdAt: Fixtures.today,
                archivedAt: nil,
                marks: []
            )
        }
    }
}
