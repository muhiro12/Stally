import Foundation
import MHPlatform
import StallyLibrary
import SwiftData

enum StallyAppActionService {
    static func resetTips() throws {
        try StallyTips.reset()
    }

    static func toggleTodayMark(
        context: ModelContext,
        item: Item,
        logger: MHLogger? = nil
    ) throws {
        do {
            _ = try MarkService.toggle(
                context: context,
                item: item
            )
        } catch {
            logger?.error(
                "failed to toggle today's mark",
                metadata: mutationMetadata(
                    error,
                    operation: "toggleTodayMark",
                    itemID: item.id
                )
            )
            throw error
        }
    }

    static func toggleArchiveState(
        context: ModelContext,
        item: Item,
        logger: MHLogger? = nil
    ) throws {
        do {
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
        } catch {
            logger?.error(
                "failed to change archive state",
                metadata: mutationMetadata(
                    error,
                    operation: "toggleArchiveState",
                    itemID: item.id,
                    extra: [
                        "wasArchived": item.isArchived ? "true" : "false"
                    ]
                )
            )
            throw error
        }
    }

    static func archive(
        context: ModelContext,
        item: Item,
        logger: MHLogger? = nil
    ) throws {
        guard !item.isArchived else {
            return
        }

        do {
            try ItemService.archive(
                context: context,
                item: item
            )
        } catch {
            logger?.error(
                "failed to archive item",
                metadata: mutationMetadata(
                    error,
                    operation: "archiveItem",
                    itemID: item.id
                )
            )
            throw error
        }
    }

    static func archive(
        context: ModelContext,
        items: [Item],
        logger: MHLogger? = nil
    ) throws {
        guard !items.isEmpty else {
            return
        }

        do {
            try ItemService.archive(
                context: context,
                items: items
            )
        } catch {
            logger?.error(
                "failed to archive items",
                metadata: mutationMetadata(
                    error,
                    operation: "archiveItems",
                    itemCount: items.count
                )
            )
            throw error
        }
    }

    static func unarchive(
        context: ModelContext,
        item: Item,
        logger: MHLogger? = nil
    ) throws {
        guard item.isArchived else {
            return
        }

        do {
            try ItemService.unarchive(
                context: context,
                item: item
            )
        } catch {
            logger?.error(
                "failed to unarchive item",
                metadata: mutationMetadata(
                    error,
                    operation: "unarchiveItem",
                    itemID: item.id
                )
            )
            throw error
        }
    }

    static func unarchive(
        context: ModelContext,
        items: [Item],
        logger: MHLogger? = nil
    ) throws {
        guard !items.isEmpty else {
            return
        }

        do {
            try ItemService.unarchive(
                context: context,
                items: items
            )
        } catch {
            logger?.error(
                "failed to unarchive items",
                metadata: mutationMetadata(
                    error,
                    operation: "unarchiveItems",
                    itemCount: items.count
                )
            )
            throw error
        }
    }

    @discardableResult
    static func setMarkState(
        context: ModelContext,
        item: Item,
        on date: Date,
        shouldBeMarked: Bool,
        logger: MHLogger? = nil
    ) throws -> Bool {
        do {
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
        } catch {
            logger?.error(
                "failed to update item mark state",
                metadata: mutationMetadata(
                    error,
                    operation: "setMarkState",
                    itemID: item.id,
                    extra: [
                        "shouldBeMarked": shouldBeMarked ? "true" : "false",
                        "date": date.ISO8601Format()
                    ]
                )
            )
            throw error
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

private extension StallyAppActionService {
    static func mutationMetadata(
        _ error: any Error,
        operation: String,
        itemID: UUID? = nil,
        itemCount: Int? = nil,
        extra: [String: String] = [:]
    ) -> [String: String] {
        var metadata = extra

        metadata["operation"] = operation
        metadata["error"] = String(describing: error)

        if let itemID {
            metadata["itemID"] = itemID.uuidString
        }

        if let itemCount {
            metadata["itemCount"] = "\(itemCount)"
        }

        return metadata
    }
}
