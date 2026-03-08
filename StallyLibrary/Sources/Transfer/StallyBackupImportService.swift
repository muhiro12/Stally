import Foundation
import SwiftData

public struct StallyBackupImportResult: Equatable, Sendable {
    public let analysis: StallyBackupImportAnalysis
    public let createdItems: Int
    public let updatedItems: Int
    public let insertedMarks: Int
    public let skippedMarks: Int

    public init(
        analysis: StallyBackupImportAnalysis,
        createdItems: Int,
        updatedItems: Int,
        insertedMarks: Int,
        skippedMarks: Int
    ) {
        self.analysis = analysis
        self.createdItems = createdItems
        self.updatedItems = updatedItems
        self.insertedMarks = insertedMarks
        self.skippedMarks = skippedMarks
    }
}

public struct StallyBackupImportValidationError: Error, Equatable, Sendable {
    public let issues: [StallyBackupImportIssue]

    public init(
        issues: [StallyBackupImportIssue]
    ) {
        self.issues = issues
    }
}

public enum StallyBackupImportService {
    public static func merge(
        context: ModelContext,
        snapshot: StallyBackupSnapshot
    ) throws -> StallyBackupImportResult {
        let existingItems = try context.fetch(FetchDescriptor<Item>())
        let analysis = StallyBackupImportAnalyzer.analyze(
            snapshot: snapshot,
            existingItemIDs: Set(existingItems.map(\.id))
        )

        guard analysis.canImport else {
            throw StallyBackupImportValidationError(
                issues: analysis.errors
            )
        }

        var existingItemsByID: [UUID: Item] = Dictionary(
            uniqueKeysWithValues: existingItems.map { ($0.id, $0) }
        )
        var createdItems = 0
        var updatedItems = 0
        var insertedMarks = 0
        var skippedMarks = 0
        var didChange = false

        for backupItem in snapshot.items {
            let item: Item
            let shouldApplyBackupMetadata: Bool

            if let existingItem = existingItemsByID[backupItem.id] {
                item = existingItem
                shouldApplyBackupMetadata = backupItem.updatedAt >= existingItem.updatedAt

                if shouldApplyBackupMetadata {
                    apply(
                        backupItem: backupItem,
                        to: existingItem
                    )
                    updatedItems += 1
                    didChange = true
                }
            } else {
                let newItem = makeItem(from: backupItem)
                context.insert(newItem)
                existingItemsByID[newItem.id] = newItem
                item = newItem
                shouldApplyBackupMetadata = true
                createdItems += 1
                didChange = true
            }

            var existingMarkIDs = Set(item.marks.map(\.id))
            var existingMarkDays = Set(item.marks.map(\.day))

            for backupMark in backupItem.marks {
                let normalizedDay = DayStamp.storageDate(from: backupMark.day)

                if existingMarkIDs.contains(backupMark.id) || existingMarkDays.contains(normalizedDay) {
                    skippedMarks += 1
                    continue
                }

                let mark = Mark(
                    id: backupMark.id,
                    item: item,
                    day: normalizedDay,
                    createdAt: backupMark.createdAt
                )
                context.insert(mark)
                existingMarkIDs.insert(mark.id)
                existingMarkDays.insert(mark.day)
                insertedMarks += 1
                didChange = true
            }

            if !shouldApplyBackupMetadata && backupItem.archivedAt != item.archivedAt {
                // Preserve newer local state when metadata is newer locally.
                _ = item
            }
        }

        if didChange {
            try context.save()
        }

        return .init(
            analysis: analysis,
            createdItems: createdItems,
            updatedItems: updatedItems,
            insertedMarks: insertedMarks,
            skippedMarks: skippedMarks
        )
    }
}

private extension StallyBackupImportService {
    static func makeItem(
        from backupItem: StallyBackupItem
    ) -> Item {
        Item(
            id: backupItem.id,
            name: backupItem.name,
            category: backupItem.category,
            photoData: backupItem.photoData,
            note: backupItem.note,
            createdAt: backupItem.createdAt,
            updatedAt: backupItem.updatedAt,
            archivedAt: backupItem.archivedAt
        )
    }

    static func apply(
        backupItem: StallyBackupItem,
        to item: Item
    ) {
        item.applyImportedSnapshot(backupItem)
    }
}
