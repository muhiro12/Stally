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
        importPlan(
            snapshot: snapshot,
            currentItems: currentItems,
            calendar: calendar
        )
        .preview(replacingExistingItems: false)
    }
}

extension BackupOperations {
    static func importPlan(
        snapshot: BackupSnapshot,
        currentItems: [Item],
        calendar: Calendar
    ) -> BackupImportPlan {
        let validItems = validImportItems(in: snapshot.items)
        let validationIssues = validationIssues(
            for: snapshot,
            currentItems: currentItems,
            calendar: calendar
        )
        let mergeItemPlans: [BackupItemImportPlan]
        let replacementItemPlans: [BackupItemImportPlan]

        if validationIssues.isEmpty {
            mergeItemPlans = itemPlans(
                from: snapshot.items,
                currentItems: currentItems,
                replacingExistingItems: false,
                calendar: calendar
            )
            replacementItemPlans = itemPlans(
                from: snapshot.items,
                currentItems: [],
                replacingExistingItems: true,
                calendar: calendar
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

    static func validationIssues(
        for snapshot: BackupSnapshot,
        currentItems: [Item],
        calendar: Calendar
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
        issues.append(contentsOf: duplicateMarkDayIssues(in: snapshot.items, calendar: calendar))
        issues.append(contentsOf: itemNameRequiredIssues(in: snapshot.items))
        issues.append(contentsOf: unknownCategoryIssues(in: snapshot.items))
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

    static func duplicateMarkDayIssues(
        in items: [BackupItem],
        calendar: Calendar
    ) -> [BackupValidationIssue] {
        items.flatMap { item in
            let duplicateDays = duplicateValues(item.marks.map { mark in
                calendar.startOfDay(for: mark.day)
            })

            return duplicateDays.map { day in
                BackupValidationIssue(
                    kind: .duplicateMarkDay,
                    value: "\(item.id.uuidString):\(calendarDayIdentifier(for: day, calendar: calendar))"
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

    static func calendarDayIdentifier(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0

        return "\(year)-\(month)-\(day)"
    }

    static func itemPlans(
        from backupItems: [BackupItem],
        currentItems: [Item],
        replacingExistingItems: Bool,
        calendar: Calendar
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
                knownMarkIDs: &knownMarkIDs,
                calendar: calendar
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
        knownMarkIDs: inout Set<UUID>,
        calendar: Calendar
    ) -> [BackupMark] {
        var plannedMarks: [BackupMark] = []

        for backupMark in backupMarks {
            guard !knownMarkIDs.contains(backupMark.id) else {
                continue
            }

            if let existingItem,
               !shouldAddMark(backupMark, to: existingItem, calendar: calendar) {
                continue
            }

            guard !plannedMarks.contains(where: { plannedMark in
                calendar.isDate(plannedMark.day, inSameDayAs: backupMark.day)
            }) else {
                continue
            }

            knownMarkIDs.insert(backupMark.id)
            plannedMarks.append(backupMark)
        }

        return plannedMarks
    }
}
