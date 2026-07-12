//
//  BackupOperationsTests.swift
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
    struct BackupOperationsTests {
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
        func `export data builds versioned preview with collection counts`() throws {
            let context = try makeContext()
            let activeItem = try createItem(
                context: context,
                name: "Black Wool Coat",
                category: .clothing,
                note: "The one I reach for on cold mornings.",
                photoData: Data([0x01])
            )
            let archivedItem = try createItem(
                context: context,
                name: "Travel Weekender",
                category: .bags
            )
            try mark(activeItem, offsets: [0], context: context)
            try mark(archivedItem, offsets: [-4], context: context)
            try ItemOperations.archive(archivedItem, on: Fixtures.timestamp(offset: -1), context: context)

            let data = try BackupOperations.exportData(
                for: try fetchItems(context),
                exportedAt: Fixtures.timestamp()
            )
            let snapshot = try JSONDecoder().decode(BackupSnapshot.self, from: data)
            let preview = BackupOperations.preview(
                data: data,
                currentItems: []
            )

            #expect(BackupOperations.fileExtension == "stallybackup")
            #expect(snapshot.schemaVersion == BackupSnapshot.currentSchemaVersion)
            #expect(snapshot.items.map(\.id).contains(activeItem.uuid))
            #expect(snapshot.items.first { item in item.id == activeItem.uuid }?.photoData == Data([0x01]))
            #expect(preview.itemCount == 2)
            #expect(preview.archivedItemCount == 1)
            #expect(preview.markCount == 2)
            #expect(preview.existingItemCount == 0)
            #expect(preview.newItemCount == 2)
            #expect(preview.marksAddedCount == 2)
            #expect(preview.canImport)
        }

        @Test
        func `merge preserves existing item context and adds missing history`() throws {
            let context = try makeContext()
            let existingItem = try createItem(
                context: context,
                name: "Canvas Tote",
                category: .bags,
                note: "Usually comes with me when I need one extra layer."
            )
            try mark(existingItem, offsets: [0], context: context)
            let newItemID = UUID()
            let existingItemMark = try #require(existingItem.marks.first)
            let snapshot = mergeSnapshot(
                existingItemID: existingItem.uuid,
                existingMarkID: existingItemMark.uuid,
                newItemID: newItemID
            )

            let result = try BackupOperations.mergeIntoLibrary(
                snapshot: snapshot,
                context: context
            )
            let items = try fetchItems(context)
            let mergedExistingItem = try #require(items.first { item in
                item.uuid == existingItem.uuid
            })
            let insertedItem = try #require(items.first { item in
                item.uuid == newItemID
            })

            #expect(result.preview.existingItemCount == 1)
            #expect(result.preview.newItemCount == 1)
            #expect(result.preview.marksAddedCount == result.insertedMarkCount)
            #expect(result.insertedItemCount == 1)
            #expect(result.insertedMarkCount == 2)
            #expect(!result.didReplaceLibrary)
            #expect(mergedExistingItem.name == "Canvas Tote")
            #expect(mergedExistingItem.category == .bags)
            #expect(mergedExistingItem.note == "Usually comes with me when I need one extra layer.")
            let mergedHistory = ItemOperations.historySnapshot(
                for: mergedExistingItem,
                today: Fixtures.today
            )
            #expect(mergedHistory.totalMarks == 2)
            #expect(insertedItem.name == "Daily Field Notes")
            #expect(insertedItem.note == "Still waiting for its first stretch of regular use.")
            #expect(ItemOperations.historySnapshot(for: insertedItem, today: Fixtures.today).totalMarks == 1)
        }

        @Test
        func `replace removes current library and restores backup snapshot`() throws {
            let context = try makeContext()
            let localItem = try createItem(context: context, name: "Local Item")
            let backupItemID = localItem.uuid
            try mark(localItem, offsets: [-5], context: context)
            let snapshot = BackupSnapshot(
                exportedAt: Fixtures.timestamp(),
                items: [
                    .init(
                        id: backupItemID,
                        name: "Travel Weekender",
                        categoryRawValue: ItemCategory.bags.rawValue,
                        note: "Archived because it only comes out a few times a year.",
                        photoData: Data([0x09]),
                        createdAt: Fixtures.timestamp(offset: -10),
                        archivedAt: Fixtures.timestamp(offset: -1),
                        marks: [
                            .init(
                                id: UUID(),
                                day: Fixtures.day(offset: -5),
                                createdAt: Fixtures.timestamp(offset: -5)
                            )
                        ]
                    )
                ]
            )

            let result = try BackupOperations.replaceLibrary(
                snapshot: snapshot,
                context: context
            )
            let items = try fetchItems(context)
            let restoredItem = try #require(items.first)

            #expect(result.didReplaceLibrary)
            #expect(result.insertedItemCount == 1)
            #expect(result.insertedMarkCount == 1)
            #expect(result.preview.existingItemCount == 0)
            #expect(result.preview.newItemCount == result.insertedItemCount)
            #expect(result.preview.marksAddedCount == result.insertedMarkCount)
            #expect(items.count == 1)
            #expect(restoredItem.uuid == backupItemID)
            #expect(restoredItem.isArchived)
            #expect(restoredItem.photoData == Data([0x09]))
            #expect(ItemOperations.historySnapshot(for: restoredItem, today: Fixtures.today).totalMarks == 1)
        }

        private func makeContext() throws -> ModelContext {
            .init(try StallyModelContainerFactory.inMemory())
        }

        private func fetchItems(_ context: ModelContext) throws -> [Item] {
            try context.fetch(.init())
        }

        private func createItem(
            context: ModelContext,
            name: String,
            category: ItemCategory = .other,
            note: String = "",
            photoData: Data? = nil
        ) throws -> Item {
            try ItemOperations.create(
                context: context,
                input: .init(
                    name: name,
                    category: category,
                    note: note,
                    photoData: photoData
                ),
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

        private func mergeSnapshot(
            existingItemID: UUID,
            existingMarkID: UUID,
            newItemID: UUID
        ) -> BackupSnapshot {
            .init(
                exportedAt: Fixtures.timestamp(),
                items: [
                    existingBackupItem(id: existingItemID, existingMarkID: existingMarkID),
                    newBackupItem(id: newItemID)
                ]
            )
        }

        private func existingBackupItem(id: UUID, existingMarkID: UUID) -> BackupItem {
            .init(
                id: id,
                name: "Remote Canvas Tote",
                categoryRawValue: ItemCategory.shoes.rawValue,
                note: "Remote note should not overwrite local context.",
                photoData: nil,
                createdAt: Fixtures.timestamp(offset: -20),
                archivedAt: nil,
                marks: [
                    .init(id: existingMarkID, day: Fixtures.today, createdAt: Fixtures.timestamp()),
                    .init(
                        id: UUID(),
                        day: Fixtures.day(offset: -2),
                        createdAt: Fixtures.timestamp(offset: -2)
                    )
                ]
            )
        }

        private func newBackupItem(id: UUID) -> BackupItem {
            .init(
                id: id,
                name: "  Daily Field Notes  ",
                categoryRawValue: ItemCategory.notebooks.rawValue,
                note: "  Still waiting for its first stretch of regular use.  ",
                photoData: nil,
                createdAt: Fixtures.timestamp(offset: -3),
                archivedAt: nil,
                marks: [
                    .init(
                        id: UUID(),
                        day: Fixtures.day(offset: -1),
                        createdAt: Fixtures.timestamp(offset: -1)
                    )
                ]
            )
        }
    }
}
