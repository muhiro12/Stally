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

@Suite(.serialized)
struct BackupOperationsTests {
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
        try ItemOperations.archive(archivedItem, on: Fixtures.day(offset: -1), context: context)

        let data = try BackupOperations.exportData(
            for: try fetchItems(context),
            exportedAt: Fixtures.today
        )
        let snapshot = try JSONDecoder().decode(BackupSnapshot.self, from: data)
        let preview = BackupOperations.preview(
            data: data,
            currentItems: [],
            calendar: Fixtures.calendar
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
            context: context,
            calendar: Fixtures.calendar
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
        #expect(result.insertedItemCount == 1)
        #expect(result.insertedMarkCount == 2)
        #expect(!result.didReplaceLibrary)
        #expect(mergedExistingItem.name == "Canvas Tote")
        #expect(mergedExistingItem.category == .bags)
        #expect(mergedExistingItem.note == "Usually comes with me when I need one extra layer.")
        #expect(ItemOperations.historySnapshot(for: mergedExistingItem, calendar: Fixtures.calendar).totalMarks == 2)
        #expect(insertedItem.name == "Daily Field Notes")
        #expect(insertedItem.note == "Still waiting for its first stretch of regular use.")
        #expect(ItemOperations.historySnapshot(for: insertedItem, calendar: Fixtures.calendar).totalMarks == 1)
    }

    @Test
    func `replace removes current library and restores backup snapshot`() throws {
        let context = try makeContext()
        _ = try createItem(context: context, name: "Local Item")
        let backupItemID = UUID()
        let snapshot = BackupSnapshot(
            exportedAt: Fixtures.today,
            items: [
                .init(
                    id: backupItemID,
                    name: "Travel Weekender",
                    categoryRawValue: ItemCategory.bags.rawValue,
                    note: "Archived because it only comes out a few times a year.",
                    photoData: Data([0x09]),
                    createdAt: Fixtures.day(offset: -10),
                    archivedAt: Fixtures.day(offset: -1),
                    marks: [
                        .init(
                            id: UUID(),
                            day: Fixtures.day(offset: -5),
                            createdAt: Fixtures.day(offset: -5)
                        )
                    ]
                )
            ]
        )

        let result = try BackupOperations.replaceLibrary(
            snapshot: snapshot,
            context: context,
            calendar: Fixtures.calendar
        )
        let items = try fetchItems(context)
        let restoredItem = try #require(items.first)

        #expect(result.didReplaceLibrary)
        #expect(result.insertedItemCount == 1)
        #expect(result.insertedMarkCount == 1)
        #expect(items.count == 1)
        #expect(restoredItem.uuid == backupItemID)
        #expect(restoredItem.isArchived)
        #expect(restoredItem.photoData == Data([0x09]))
        #expect(ItemOperations.historySnapshot(for: restoredItem, calendar: Fixtures.calendar).totalMarks == 1)
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

    private func mergeSnapshot(
        existingItemID: UUID,
        existingMarkID: UUID,
        newItemID: UUID
    ) -> BackupSnapshot {
        .init(
            exportedAt: Fixtures.today,
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
            createdAt: Fixtures.day(offset: -20),
            archivedAt: nil,
            marks: [
                .init(id: existingMarkID, day: Fixtures.today, createdAt: Fixtures.today),
                .init(id: UUID(), day: Fixtures.day(offset: -2), createdAt: Fixtures.day(offset: -2))
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
            createdAt: Fixtures.day(offset: -3),
            archivedAt: nil,
            marks: [
                .init(id: UUID(), day: Fixtures.day(offset: -1), createdAt: Fixtures.day(offset: -1))
            ]
        )
    }
}
