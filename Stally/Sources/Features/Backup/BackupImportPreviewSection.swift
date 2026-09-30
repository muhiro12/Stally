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
    @Binding var isReplacingExistingItems: Bool
    let mergeAction: () -> Void
    let replaceAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            Picker("Import Method", selection: $isReplacingExistingItems) {
                Text("Merge Into Library").tag(false)
                Text("Replace Library").tag(true)
            }
            if !isReplacingExistingItems {
                Text(
                    """
                    Merge preserves existing details, including start dates and Mark settings, \
                    and adds missing history.
                    """
                )
                .mhTextStyle(.supporting, colorRole: .secondaryText)
            }
            BackupValidationIssueList(issues: preview.validationIssues)

            BackupPreviewRows(preview: preview)

            MHActionGroup {
                if isReplacingExistingItems {
                    Button("Replace Library", role: .destructive, action: replaceAction)
                        .disabled(!preview.canImport)
                        .buttonStyle(.mhDestructive)
                } else {
                    Button("Merge Into Library", action: mergeAction)
                        .disabled(!preview.canImport)
                        .buttonStyle(.mhPrimary)
                }
            }
        }
        .mhSection("Import Preview")
    }
}
