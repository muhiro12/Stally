import Foundation
import StallyLibrary
import SwiftData

enum StallyRootActionService {
    static func resetTips() throws {
        try StallyTips.reset()
    }

    static func toggleTodayMark(
        context: ModelContext,
        item: Item
    ) throws {
        _ = try MarkService.toggle(
            context: context,
            item: item
        )
    }

    static func toggleArchiveState(
        context: ModelContext,
        item: Item
    ) throws {
        if item.isArchived {
            try ItemService.unarchive(
                context: context,
                item: item
            )
        } else {
            try ItemService.archive(
                context: context,
                item: item
            )
        }
    }

    static func archive(
        context: ModelContext,
        item: Item
    ) throws {
        guard !item.isArchived else {
            return
        }

        try ItemService.archive(
            context: context,
            item: item
        )
    }

    static func archive(
        context: ModelContext,
        items: [Item]
    ) throws {
        guard !items.isEmpty else {
            return
        }

        try ItemService.archive(
            context: context,
            items: items
        )
    }

    static func unarchive(
        context: ModelContext,
        item: Item
    ) throws {
        guard item.isArchived else {
            return
        }

        try ItemService.unarchive(
            context: context,
            item: item
        )
    }

    static func unarchive(
        context: ModelContext,
        items: [Item]
    ) throws {
        guard !items.isEmpty else {
            return
        }

        try ItemService.unarchive(
            context: context,
            items: items
        )
    }

    @discardableResult
    static func setMarkState(
        context: ModelContext,
        item: Item,
        on date: Date,
        shouldBeMarked: Bool
    ) throws -> Bool {
        if shouldBeMarked {
            _ = try MarkService.mark(
                context: context,
                item: item,
                on: date
            )
        } else {
            _ = try MarkService.unmark(
                context: context,
                item: item,
                on: date
            )
        }

        return true
    }

    static func seedSampleData(
        context: ModelContext
    ) throws {
        try ItemService.seedSampleData(
            context: context,
            ifEmptyOnly: true
        )
    }

    static func mergeImport(
        context: ModelContext,
        snapshot: StallyBackupSnapshot
    ) throws -> StallyBackupImportResult {
        try StallyBackupImportService.merge(
            context: context,
            snapshot: snapshot
        )
    }

    static func replaceImport(
        context: ModelContext,
        snapshot: StallyBackupSnapshot
    ) throws -> StallyBackupImportResult {
        try StallyBackupImportService.replace(
            context: context,
            snapshot: snapshot
        )
    }

    static func deleteAllItems(
        context: ModelContext
    ) throws {
        try ItemService.deleteAll(
            context: context
        )
    }
}
