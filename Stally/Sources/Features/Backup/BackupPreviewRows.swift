//
//  BackupPreviewRows.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import SwiftUI

struct BackupPreviewRows: View {
    let preview: BackupPreview

    var body: some View {
        LabeledContent("Items") {
            Text(preview.itemCount, format: .number)
        }

        LabeledContent("Archived") {
            Text(preview.archivedItemCount, format: .number)
        }

        LabeledContent("Marks") {
            Text(preview.markCount, format: .number)
        }

        LabeledContent("Existing") {
            Text(preview.existingItemCount, format: .number)
        }

        LabeledContent("New") {
            Text(preview.newItemCount, format: .number)
        }

        LabeledContent("Skipped") {
            Text(preview.skippedItemCount, format: .number)
        }

        LabeledContent("Marks Added") {
            Text(preview.marksAddedCount, format: .number)
        }

        BackupValidationIssueList(issues: preview.validationIssues)
    }
}
