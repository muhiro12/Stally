//
//  BackupOperations+Preview.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

import Foundation

public extension BackupOperations {
    /// Previews an import before applying it to the local library.
    static func preview(
        data: Data,
        currentItems: [Item],
        calendar: Calendar = .current,
        decoder: JSONDecoder = .init()
    ) -> BackupPreview {
        guard let snapshot = try? decoder.decode(BackupSnapshot.self, from: data) else {
            return unreadablePreview()
        }

        return preview(
            snapshot: snapshot,
            currentItems: currentItems,
            calendar: calendar
        )
    }

    /// Previews an import before applying it to the local library.
    static func preview(
        snapshot: BackupSnapshot,
        currentItems: [Item],
        calendar: Calendar = .current
    ) -> BackupPreview {
        let validItems = validImportItems(in: snapshot.items)

        return .init(
            itemCount: snapshot.items.count,
            archivedItemCount: archivedItemCount(in: snapshot.items),
            markCount: markCount(in: snapshot.items),
            existingItemCount: existingItemCount(in: validItems, currentItems: currentItems),
            newItemCount: newItemCount(in: validItems, currentItems: currentItems),
            skippedItemCount: snapshot.items.count - validItems.count,
            marksAddedCount: predictedMarksAdded(
                from: validItems,
                currentItems: currentItems,
                calendar: calendar
            ),
            validationIssues: validationIssues(for: snapshot)
        )
    }
}

extension BackupOperations {
    static func unreadablePreview() -> BackupPreview {
        .init(
            itemCount: 0,
            archivedItemCount: 0,
            markCount: 0,
            existingItemCount: 0,
            newItemCount: 0,
            skippedItemCount: 0,
            marksAddedCount: 0,
            validationIssues: [.init(kind: .unreadableBackup)]
        )
    }

    static func validationIssues(for snapshot: BackupSnapshot) -> [BackupValidationIssue] {
        var issues: [BackupValidationIssue] = []

        if snapshot.schemaVersion != BackupSnapshot.currentSchemaVersion {
            issues.append(
                .init(
                    kind: .unsupportedSchemaVersion,
                    value: "\(snapshot.schemaVersion)"
                )
            )
        }

        issues.append(contentsOf: duplicateItemIDIssues(in: snapshot.items))
        issues.append(contentsOf: duplicateMarkIDIssues(in: snapshot.items))
        issues.append(contentsOf: itemNameRequiredIssues(in: snapshot.items))
        issues.append(contentsOf: unknownCategoryIssues(in: snapshot.items))

        return issues
    }

    static func itemFormInput(from item: BackupItem) -> ItemFormInput {
        .init(
            name: item.name,
            category: ItemCategory(rawValue: item.categoryRawValue) ?? .other,
            note: item.note,
            photoData: item.photoData
        )
    }
}

private extension BackupOperations {
    static func validImportItems(in items: [BackupItem]) -> [BackupItem] {
        items.filter { item in
            ItemCategory(rawValue: item.categoryRawValue) != nil
                && !itemFormInput(from: item).normalizedName.isEmpty
        }
    }

    static func archivedItemCount(in items: [BackupItem]) -> Int {
        items.filter { item in
            item.archivedAt != nil
        }
        .count
    }

    static func markCount(in items: [BackupItem]) -> Int {
        items.reduce(0) { count, item in
            count + item.marks.count
        }
    }

    static func existingItemCount(in backupItems: [BackupItem], currentItems: [Item]) -> Int {
        let existingItemIDs = Set(currentItems.map(\.uuid))

        return backupItems.filter { item in
            existingItemIDs.contains(item.id)
        }
        .count
    }

    static func newItemCount(in backupItems: [BackupItem], currentItems: [Item]) -> Int {
        let existingItemIDs = Set(currentItems.map(\.uuid))

        return backupItems.filter { item in
            !existingItemIDs.contains(item.id)
        }
        .count
    }

    static func duplicateItemIDIssues(in items: [BackupItem]) -> [BackupValidationIssue] {
        let duplicateIDs = duplicateValues(items.map(\.id))

        return duplicateIDs.map { id in
            .init(kind: .duplicateItemID, value: id.uuidString)
        }
    }

    static func duplicateMarkIDIssues(in items: [BackupItem]) -> [BackupValidationIssue] {
        let duplicateIDs = duplicateValues(items.flatMap { item in
            item.marks.map(\.id)
        })

        return duplicateIDs.map { id in
            .init(kind: .duplicateMarkID, value: id.uuidString)
        }
    }

    static func itemNameRequiredIssues(in items: [BackupItem]) -> [BackupValidationIssue] {
        items
            .filter { item in
                itemFormInput(from: item).normalizedName.isEmpty
            }
            .map { item in
                .init(kind: .itemNameRequired, value: item.id.uuidString)
            }
    }

    static func unknownCategoryIssues(in items: [BackupItem]) -> [BackupValidationIssue] {
        let unknownCategories = Set(
            items
                .map(\.categoryRawValue)
                .filter { categoryRawValue in
                    ItemCategory(rawValue: categoryRawValue) == nil
                }
        )

        return unknownCategories.sorted().map { categoryRawValue in
            .init(kind: .unknownCategory, value: categoryRawValue)
        }
    }

    static func duplicateValues<Value: Hashable>(_ values: [Value]) -> [Value] {
        var seenValues = Set<Value>()
        var duplicateValues = Set<Value>()

        for value in values where !seenValues.insert(value).inserted {
            duplicateValues.insert(value)
        }

        return duplicateValues.sorted { lhsValue, rhsValue in
            String(describing: lhsValue) < String(describing: rhsValue)
        }
    }

    static func predictedMarksAdded(
        from backupItems: [BackupItem],
        currentItems: [Item],
        calendar: Calendar
    ) -> Int {
        let currentMarkIDs = Set(currentItems.flatMap { item in
            item.marks.map(\.uuid)
        })
        let existingItemsByID = Dictionary(uniqueKeysWithValues: currentItems.map { item in
            (item.uuid, item)
        })

        return backupItems.reduce(0) { count, backupItem in
            count + predictedMarksAdded(
                from: backupItem,
                currentMarkIDs: currentMarkIDs,
                existingItemsByID: existingItemsByID,
                calendar: calendar
            )
        }
    }

    static func predictedMarksAdded(
        from backupItem: BackupItem,
        currentMarkIDs: Set<UUID>,
        existingItemsByID: [UUID: Item],
        calendar: Calendar
    ) -> Int {
        guard let existingItem = existingItemsByID[backupItem.id] else {
            return backupItem.marks.filter { backupMark in
                !currentMarkIDs.contains(backupMark.id)
            }
            .count
        }

        return backupItem.marks.filter { backupMark in
            !currentMarkIDs.contains(backupMark.id) && shouldAddMark(
                backupMark,
                to: existingItem,
                calendar: calendar
            )
        }
        .count
    }
}
