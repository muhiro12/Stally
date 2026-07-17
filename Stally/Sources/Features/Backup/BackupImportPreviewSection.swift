//
//  BackupImportPreviewSection.swift
//  Stally
//
//  Created by Codex on 2026/07/18.
//

import MHUI
import SwiftUI

struct BackupImportPreviewSection: View {
    @Environment(\.mhTheme)
    private var theme

    let preview: BackupPreview
    let mergeAction: () -> Void
    let replaceAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            BackupValidationIssueList(issues: preview.validationIssues)

            BackupPreviewRows(preview: preview)

            MHActionGroup {
                Button("Merge Into Library", action: mergeAction)
                    .disabled(!preview.canImport)
                    .buttonStyle(.mhPrimary)

                Button("Replace Library", role: .destructive, action: replaceAction)
                    .disabled(!preview.canImport)
                    .buttonStyle(.mhDestructive)
            }
        }
        .mhSection("Backup Preview")
    }
}
