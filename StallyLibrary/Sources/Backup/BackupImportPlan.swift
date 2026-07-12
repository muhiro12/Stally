//
//  BackupImportPlan.swift
//  StallyLibrary
//
//  Created by Codex on 2026/07/12.
//

struct BackupImportPlan {
    let mergePreview: BackupPreview
    let mergeItemPlans: [BackupItemImportPlan]
    let replacementItemPlans: [BackupItemImportPlan]

    func preview(replacingExistingItems: Bool) -> BackupPreview {
        guard replacingExistingItems, mergePreview.canImport else {
            return mergePreview
        }

        let counts = resultCounts(replacingExistingItems: true)

        return .init(
            itemCount: mergePreview.itemCount,
            archivedItemCount: mergePreview.archivedItemCount,
            markCount: mergePreview.markCount,
            existingItemCount: 0,
            newItemCount: counts.insertedItemCount,
            skippedItemCount: mergePreview.skippedItemCount,
            marksAddedCount: counts.insertedMarkCount,
            validationIssues: mergePreview.validationIssues
        )
    }

    func resultCounts(replacingExistingItems: Bool) -> BackupImportResultCounts {
        let itemPlans = itemPlans(replacingExistingItems: replacingExistingItems)

        return .init(
            insertedItemCount: itemPlans.filter { itemPlan in
                itemPlan.existingItem == nil
            }
            .count,
            insertedMarkCount: itemPlans.reduce(0) { count, itemPlan in
                count + itemPlan.marks.count
            }
        )
    }

    func itemPlans(replacingExistingItems: Bool) -> [BackupItemImportPlan] {
        if replacingExistingItems {
            replacementItemPlans
        } else {
            mergeItemPlans
        }
    }
}
