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
        decoder: JSONDecoder = .init()
    ) -> BackupPreview {
        guard data.count <= maximumImportDataByteCount else {
            return oversizedImportPreview(dataByteCount: data.count)
        }

        guard let schemaVersion = try? schemaVersion(in: data, decoder: decoder) else {
            return unreadablePreview()
        }

        guard schemaVersion == BackupSnapshot.currentSchemaVersion else {
            return unsupportedSchemaPreview(schemaVersion)
        }

        guard let snapshot = try? decoder.decode(BackupSnapshot.self, from: data) else {
            return unreadablePreview()
        }

        return preview(
            snapshot: snapshot,
            currentItems: currentItems
        )
    }

    /// Previews an import before applying it to the local library.
    static func preview(
        snapshot: BackupSnapshot,
        currentItems: [Item]
    ) -> BackupPreview {
        importPlan(
            snapshot: snapshot,
            currentItems: currentItems
        )
        .preview(replacingExistingItems: false)
    }
}

extension BackupOperations {
    static func importPlan(
        snapshot: BackupSnapshot,
        currentItems: [Item]
    ) -> BackupImportPlan {
        let validationIssues = validationIssues(
            for: snapshot,
            currentItems: currentItems
        )
        let validItems = validImportItems(
            in: snapshot.items,
            invalidPhotoIdentifiers: invalidItemPhotoIdentifiers(in: validationIssues)
        )
        let mergeItemPlans: [BackupItemImportPlan]
        let replacementItemPlans: [BackupItemImportPlan]

        if validationIssues.isEmpty {
            mergeItemPlans = itemPlans(
                from: snapshot.items,
                currentItems: currentItems,
                replacingExistingItems: false
            )
            replacementItemPlans = itemPlans(
                from: snapshot.items,
                currentItems: [],
                replacingExistingItems: true
            )
        } else {
            mergeItemPlans = []
            replacementItemPlans = []
        }

        let preview = BackupPreview(
            itemCount: snapshot.items.count,
            archivedItemCount: archivedItemCount(in: snapshot.items),
            markCount: markCount(in: snapshot.items),
            existingItemCount: existingItemCount(in: validItems, currentItems: currentItems),
            newItemCount: newItemCount(in: validItems, currentItems: currentItems),
            skippedItemCount: snapshot.items.count - validItems.count,
            marksAddedCount: mergeItemPlans.reduce(0) { count, itemPlan in
                count + itemPlan.marks.count
            },
            validationIssues: validationIssues
        )

        return .init(
            mergePreview: preview,
            mergeItemPlans: mergeItemPlans,
            replacementItemPlans: replacementItemPlans
        )
    }

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

    static func unsupportedSchemaPreview(_ schemaVersion: Int) -> BackupPreview {
        .init(
            itemCount: 0,
            archivedItemCount: 0,
            markCount: 0,
            existingItemCount: 0,
            newItemCount: 0,
            skippedItemCount: 0,
            marksAddedCount: 0,
            validationIssues: [
                .init(
                    kind: .unsupportedSchemaVersion,
                    value: "\(schemaVersion)"
                )
            ]
        )
    }

    static func schemaVersion(
        in data: Data,
        decoder: JSONDecoder
    ) throws -> Int {
        try decoder.decode(BackupSchemaEnvelope.self, from: data).schemaVersion
    }

    static func validationIssues(
        for snapshot: BackupSnapshot,
        currentItems: [Item]
    ) -> [BackupValidationIssue] {
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
        issues.append(contentsOf: duplicateMarkDayIssues(in: snapshot.items))
        issues.append(contentsOf: itemNameRequiredIssues(in: snapshot.items))
        issues.append(contentsOf: unknownCategoryIssues(in: snapshot.items))

        if let issue = photoStorageLimitIssue(in: snapshot.items) {
            issues.append(issue)
        } else {
            issues.append(contentsOf: itemPhotoValidationIssues(in: snapshot.items))
        }

        issues.append(contentsOf: duplicateCurrentItemIDIssues(in: currentItems))

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
    struct BackupSchemaEnvelope: Decodable {
        let schemaVersion: Int
    }

    static func validImportItems(
        in items: [BackupItem],
        invalidPhotoIdentifiers: Set<String>
    ) -> [BackupItem] {
        items.filter { item in
            ItemCategory(rawValue: item.categoryRawValue) != nil
                && !itemFormInput(from: item).normalizedName.isEmpty
                && !invalidPhotoIdentifiers.contains(item.id.uuidString)
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

    static func duplicateMarkDayIssues(in items: [BackupItem]) -> [BackupValidationIssue] {
        items.flatMap { item in
            let duplicateDays = duplicateValues(item.marks.map(\.day))

            return duplicateDays.map { day in
                BackupValidationIssue(
                    kind: .duplicateMarkDay,
                    value: "\(item.id.uuidString):\(localDayIdentifier(day))"
                )
            }
        }
    }

    static func duplicateCurrentItemIDIssues(in items: [Item]) -> [BackupValidationIssue] {
        duplicateValues(items.map(\.uuid)).map { id in
            .init(kind: .duplicateCurrentItemID, value: id.uuidString)
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

    static func localDayIdentifier(_ day: LocalDay) -> String {
        day.iso8601Date
    }

    static func itemPlans(
        from backupItems: [BackupItem],
        currentItems: [Item],
        replacingExistingItems: Bool
    ) -> [BackupItemImportPlan] {
        let currentItemsByID = currentItemIndex(currentItems)
        var knownMarkIDs = Set(replacingExistingItems ? [] : currentItems.flatMap { item in
            item.marks.map(\.uuid)
        })
        var itemPlans: [BackupItemImportPlan] = []

        for backupItem in backupItems {
            let existingItem = replacingExistingItems ? nil : currentItemsByID[backupItem.id]
            let marks = plannedMarks(
                from: backupItem.marks,
                existingItem: existingItem,
                knownMarkIDs: &knownMarkIDs
            )
            itemPlans.append(
                .init(
                    backupItem: backupItem,
                    existingItem: existingItem,
                    marks: marks
                )
            )
        }

        return itemPlans
    }

    static func currentItemIndex(_ items: [Item]) -> [UUID: Item] {
        var itemsByID: [UUID: Item] = [:]

        for item in items {
            guard itemsByID[item.uuid] == nil else {
                continue
            }

            itemsByID[item.uuid] = item
        }

        return itemsByID
    }

    static func plannedMarks(
        from backupMarks: [BackupMark],
        existingItem: Item?,
        knownMarkIDs: inout Set<UUID>
    ) -> [BackupMark] {
        var plannedMarks: [BackupMark] = []

        for backupMark in backupMarks {
            guard !knownMarkIDs.contains(backupMark.id) else {
                continue
            }

            if let existingItem,
               !shouldAddMark(backupMark, to: existingItem) {
                continue
            }

            guard !plannedMarks.contains(where: { plannedMark in
                plannedMark.day == backupMark.day
            }) else {
                continue
            }

            knownMarkIDs.insert(backupMark.id)
            plannedMarks.append(backupMark)
        }

        return plannedMarks
    }
}
