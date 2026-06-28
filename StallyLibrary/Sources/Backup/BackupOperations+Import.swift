//
//  BackupOperations+Import.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

import Foundation
import SwiftData

public extension BackupOperations {
    /// Merges a valid backup into the current library.
    @discardableResult
    static func mergeIntoLibrary(
        data: Data,
        context: ModelContext,
        calendar: Calendar = .current,
        decoder: JSONDecoder = .init()
    ) throws -> BackupImportResult {
        let snapshot = try decoder.decode(BackupSnapshot.self, from: data)
        return try mergeIntoLibrary(
            snapshot: snapshot,
            context: context,
            calendar: calendar
        )
    }

    /// Merges a valid backup into the current library.
    @discardableResult
    static func mergeIntoLibrary(
        snapshot: BackupSnapshot,
        context: ModelContext,
        calendar: Calendar = .current
    ) throws -> BackupImportResult {
        let currentItems = try fetchItems(context)
        let preview = preview(
            snapshot: snapshot,
            currentItems: currentItems,
            calendar: calendar
        )

        guard preview.canImport else {
            throw BackupError.validationFailed(preview)
        }

        let mergeResult = importItems(
            snapshot.items,
            into: context,
            replacingExistingItems: false,
            currentItems: currentItems,
            calendar: calendar
        )
        try saveOrRollback(context)

        return .init(
            preview: preview,
            insertedItemCount: mergeResult.insertedItemCount,
            insertedMarkCount: mergeResult.insertedMarkCount,
            didReplaceLibrary: false
        )
    }

    /// Replaces the current library with a valid backup.
    @discardableResult
    static func replaceLibrary(
        data: Data,
        context: ModelContext,
        calendar: Calendar = .current,
        decoder: JSONDecoder = .init()
    ) throws -> BackupImportResult {
        let snapshot = try decoder.decode(BackupSnapshot.self, from: data)
        return try replaceLibrary(
            snapshot: snapshot,
            context: context,
            calendar: calendar
        )
    }

    /// Replaces the current library with a valid backup.
    @discardableResult
    static func replaceLibrary(
        snapshot: BackupSnapshot,
        context: ModelContext,
        calendar: Calendar = .current
    ) throws -> BackupImportResult {
        let currentItems = try fetchItems(context)
        let preview = preview(
            snapshot: snapshot,
            currentItems: currentItems,
            calendar: calendar
        )

        guard preview.canImport else {
            throw BackupError.validationFailed(preview)
        }

        _ = try prepareDeleteEverything(context: context)
        let importResult = importItems(
            snapshot.items,
            into: context,
            replacingExistingItems: true,
            currentItems: [],
            calendar: calendar
        )
        try saveOrRollback(context)

        return .init(
            preview: preview,
            insertedItemCount: importResult.insertedItemCount,
            insertedMarkCount: importResult.insertedMarkCount,
            didReplaceLibrary: true
        )
    }

    /// Intentionally deletes every item and mark from the local library.
    @discardableResult
    static func deleteEverything(context: ModelContext) throws -> BackupResetResult {
        let result = try prepareDeleteEverything(context: context)
        try saveOrRollback(context)
        return result
    }
}

extension BackupOperations {
    static func shouldAddMark(
        _ backupMark: BackupMark,
        to item: Item,
        calendar: Calendar
    ) -> Bool {
        !item.marks.contains { mark in
            calendar.isDate(mark.day, inSameDayAs: backupMark.day)
        }
    }
}

private extension BackupOperations {
    static func prepareDeleteEverything(context: ModelContext) throws -> BackupResetResult {
        let items = try fetchItems(context)
        let markCount = items.reduce(0) { count, item in
            count + item.marks.count
        }

        for item in items {
            context.delete(item)
        }

        return .init(
            deletedItemCount: items.count,
            deletedMarkCount: markCount
        )
    }

    static func importItems(
        _ backupItems: [BackupItem],
        into context: ModelContext,
        replacingExistingItems: Bool,
        currentItems: [Item],
        calendar: Calendar
    ) -> BackupImportResultCounts {
        let currentItemsByID = Dictionary(uniqueKeysWithValues: currentItems.map { item in
            (item.uuid, item)
        })
        var knownMarkIDs = Set(currentItems.flatMap { item in
            item.marks.map(\.uuid)
        })
        var insertedItemCount = 0
        var insertedMarkCount = 0

        for backupItem in backupItems {
            if !replacingExistingItems,
               let existingItem = currentItemsByID[backupItem.id] {
                insertedMarkCount += importMissingMarks(
                    backupItem.marks,
                    into: existingItem,
                    context: context,
                    knownMarkIDs: &knownMarkIDs,
                    calendar: calendar
                )
            } else {
                let item = item(from: backupItem)
                context.insert(item)
                insertedItemCount += 1
                insertedMarkCount += importMarks(
                    backupItem.marks,
                    into: item,
                    context: context,
                    knownMarkIDs: &knownMarkIDs,
                    calendar: calendar
                )
            }
        }

        return .init(
            insertedItemCount: insertedItemCount,
            insertedMarkCount: insertedMarkCount
        )
    }

    static func importMissingMarks(
        _ backupMarks: [BackupMark],
        into item: Item,
        context: ModelContext,
        knownMarkIDs: inout Set<UUID>,
        calendar: Calendar
    ) -> Int {
        var insertedMarkCount = 0

        for backupMark in backupMarks where shouldAddMark(backupMark, to: item, calendar: calendar) {
            guard knownMarkIDs.insert(backupMark.id).inserted else {
                continue
            }

            insertMark(backupMark, into: item, context: context)
            insertedMarkCount += 1
        }

        return insertedMarkCount
    }

    static func importMarks(
        _ backupMarks: [BackupMark],
        into item: Item,
        context: ModelContext,
        knownMarkIDs: inout Set<UUID>,
        calendar: Calendar
    ) -> Int {
        var insertedMarkCount = 0

        for backupMark in backupMarks where shouldAddMark(backupMark, to: item, calendar: calendar) {
            guard knownMarkIDs.insert(backupMark.id).inserted else {
                continue
            }

            insertMark(backupMark, into: item, context: context)
            insertedMarkCount += 1
        }

        return insertedMarkCount
    }

    static func item(from backupItem: BackupItem) -> Item {
        let input = itemFormInput(from: backupItem)

        return .init(
            name: input.normalizedName,
            category: ItemCategory(rawValue: backupItem.categoryRawValue) ?? .other,
            note: input.normalizedNote,
            createdAt: backupItem.createdAt,
            uuid: backupItem.id,
            photoData: backupItem.photoData,
            archivedAt: backupItem.archivedAt
        )
    }

    static func insertMark(
        _ backupMark: BackupMark,
        into item: Item,
        context: ModelContext
    ) {
        let mark = ItemMark(
            day: backupMark.day,
            createdAt: backupMark.createdAt,
            item: item,
            uuid: backupMark.id
        )
        item.marks.append(mark)
        context.insert(mark)
    }

    static func fetchItems(_ context: ModelContext) throws -> [Item] {
        try context.fetch(.init())
    }

    static func saveOrRollback(_ context: ModelContext) throws {
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}
