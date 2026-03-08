import Foundation
import SwiftData

/// Applies validated backup snapshots to live SwiftData storage.
public enum StallyBackupImportService {
    struct MergeCounts {
        let created: Int
        let updated: Int
        let insertedMarks: Int
        let skippedMarks: Int
        let didChange: Bool
    }

    struct UpsertOutcome {
        let item: Item
        let created: Bool
        let updated: Bool
        let didChange: Bool
    }

    struct InsertCounts {
        let createdItems: Int
        let insertedMarks: Int
    }

    /// Merges a backup snapshot into the current library.
    public static func merge(
        context: ModelContext,
        snapshot: StallyBackupSnapshot
    ) throws -> StallyBackupImportResult {
        let existingItems = try fetchExistingItems(context: context)
        let analysis = try analyze(
            snapshot: snapshot,
            existingItems: existingItems
        )
        var existingItemsByID = Dictionary(
            uniqueKeysWithValues: existingItems.map { ($0.id, $0) }
        )
        var createdItems = 0
        var updatedItems = 0
        var insertedMarks = 0
        var skippedMarks = 0
        var didChange = false

        for backupItem in snapshot.items {
            let counts = merge(
                backupItem: backupItem,
                context: context,
                existingItemsByID: &existingItemsByID
            )
            createdItems += counts.created
            updatedItems += counts.updated
            insertedMarks += counts.insertedMarks
            skippedMarks += counts.skippedMarks
            didChange = didChange || counts.didChange
        }

        if didChange {
            try context.save()
        }

        return .init(
            analysis: analysis,
            deletedItems: 0,
            createdItems: createdItems,
            updatedItems: updatedItems,
            insertedMarks: insertedMarks,
            skippedMarks: skippedMarks
        )
    }

    /// Replaces the current library with a backup snapshot.
    public static func replace(
        context: ModelContext,
        snapshot: StallyBackupSnapshot
    ) throws -> StallyBackupImportResult {
        let existingItems = try fetchExistingItems(context: context)
        let analysis = try analyze(
            snapshot: snapshot,
            existingItems: existingItems
        )
        let deletedItems = deleteExistingItems(
            existingItems,
            context: context
        )
        let counts = insertSnapshotItems(
            snapshot.items,
            context: context
        )

        if deletedItems > 0 || counts.createdItems > 0 || counts.insertedMarks > 0 {
            try context.save()
        }

        return .init(
            analysis: analysis,
            deletedItems: deletedItems,
            createdItems: counts.createdItems,
            updatedItems: 0,
            insertedMarks: counts.insertedMarks,
            skippedMarks: 0
        )
    }
}

private extension StallyBackupImportService {
    static func fetchExistingItems(
        context: ModelContext
    ) throws -> [Item] {
        try context.fetch(FetchDescriptor<Item>())
    }

    static func analyze(
        snapshot: StallyBackupSnapshot,
        existingItems: [Item]
    ) throws -> StallyBackupImportAnalysis {
        let analysis = StallyBackupImportAnalyzer.analyze(
            snapshot: snapshot,
            existingItemIDs: Set(existingItems.map(\.id))
        )

        guard analysis.canImport else {
            throw StallyBackupImportValidationError(
                issues: analysis.errors
            )
        }

        return analysis
    }

    static func merge(
        backupItem: StallyBackupItem,
        context: ModelContext,
        existingItemsByID: inout [UUID: Item]
    ) -> MergeCounts {
        let itemOutcome = upsert(
            backupItem: backupItem,
            context: context,
            existingItemsByID: &existingItemsByID
        )
        let markOutcome = mergeMarks(
            backupItem.marks,
            into: itemOutcome.item,
            context: context
        )

        return .init(
            created: itemOutcome.created ? 1 : 0,
            updated: itemOutcome.updated ? 1 : 0,
            insertedMarks: markOutcome.inserted,
            skippedMarks: markOutcome.skipped,
            didChange: itemOutcome.didChange || markOutcome.inserted > 0
        )
    }

    static func upsert(
        backupItem: StallyBackupItem,
        context: ModelContext,
        existingItemsByID: inout [UUID: Item]
    ) -> UpsertOutcome {
        if let existingItem = existingItemsByID[backupItem.id] {
            let shouldApplyBackupMetadata = backupItem.updatedAt >= existingItem.updatedAt

            if shouldApplyBackupMetadata {
                existingItem.applyImportedSnapshot(backupItem)
            }

            return .init(
                item: existingItem,
                created: false,
                updated: shouldApplyBackupMetadata,
                didChange: shouldApplyBackupMetadata
            )
        }

        let newItem = makeItem(from: backupItem)
        context.insert(newItem)
        existingItemsByID[newItem.id] = newItem

        return .init(
            item: newItem,
            created: true,
            updated: false,
            didChange: true
        )
    }

    static func mergeMarks(
        _ backupMarks: [StallyBackupMark],
        into item: Item,
        context: ModelContext
    ) -> (
        inserted: Int,
        skipped: Int
    ) {
        var existingMarkIDs = Set(item.marks.map(\.id))
        var existingMarkDays = Set(item.marks.map(\.day))
        var inserted = 0
        var skipped = 0

        for backupMark in backupMarks {
            let normalizedDay = DayStamp.storageDate(from: backupMark.day)

            if existingMarkIDs.contains(backupMark.id) || existingMarkDays.contains(normalizedDay) {
                skipped += 1
                continue
            }

            let mark = Mark(
                item: item,
                day: normalizedDay,
                createdAt: backupMark.createdAt,
                id: backupMark.id
            )
            context.insert(mark)
            existingMarkIDs.insert(mark.id)
            existingMarkDays.insert(mark.day)
            inserted += 1
        }

        return (
            inserted: inserted,
            skipped: skipped
        )
    }

    static func deleteExistingItems(
        _ items: [Item],
        context: ModelContext
    ) -> Int {
        for item in items {
            context.delete(item)
        }

        return items.count
    }

    static func insertSnapshotItems(
        _ backupItems: [StallyBackupItem],
        context: ModelContext
    ) -> InsertCounts {
        var createdItems = 0
        var insertedMarks = 0

        for backupItem in backupItems {
            let item = makeItem(from: backupItem)
            context.insert(item)
            createdItems += 1

            for backupMark in backupItem.marks {
                context.insert(
                    Mark(
                        item: item,
                        day: DayStamp.storageDate(from: backupMark.day),
                        createdAt: backupMark.createdAt,
                        id: backupMark.id
                    )
                )
                insertedMarks += 1
            }
        }

        return .init(
            createdItems: createdItems,
            insertedMarks: insertedMarks
        )
    }

    static func makeItem(
        from backupItem: StallyBackupItem
    ) -> Item {
        Item(
            name: backupItem.name,
            category: backupItem.category,
            photoData: backupItem.photoData,
            note: backupItem.note,
            createdAt: backupItem.createdAt,
            updatedAt: backupItem.updatedAt,
            archivedAt: backupItem.archivedAt,
            id: backupItem.id
        )
    }
}
