//
//  BackupImportPlan.swift
//  StallyLibrary
//
//  Created by Codex on 2026/07/12.
//

struct BackupImportPlan {
    let mergePreview: BackupPreview
    let replacementValidationIssues: [BackupValidationIssue]
    let mergeItemPlans: [BackupItemImportPlan]
    let replacementItemPlans: [BackupItemImportPlan]

    func preview(replacingExistingItems: Bool) -> BackupPreview {
        guard replacingExistingItems else {
            return mergePreview
        }

        let counts = resultCounts(replacingExistingItems: true)
        let canReplace = replacementValidationIssues.isEmpty

        return .init(
            itemCount: mergePreview.itemCount,
            archivedItemCount: mergePreview.archivedItemCount,
            markCount: mergePreview.markCount,
            existingItemCount: canReplace ? 0 : mergePreview.existingItemCount,
            newItemCount: canReplace ? counts.insertedItemCount : mergePreview.newItemCount,
            skippedItemCount: mergePreview.skippedItemCount,
            marksAddedCount: canReplace ? counts.insertedMarkCount : mergePreview.marksAddedCount,
            validationIssues: replacementValidationIssues
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
