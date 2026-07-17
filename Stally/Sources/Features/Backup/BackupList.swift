//
//  BackupList.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHUI
import SwiftUI

struct BackupList: View {
    @Environment(\.mhTheme)
    private var theme

    let summary: BackupCollectionSummary
    let preview: BackupPreview?
    let statusMessage: String?
    let exportAction: () -> Void
    let chooseBackupAction: () -> Void
    let mergeAction: () -> Void
    let replaceAction: () -> Void
    let deleteEverythingAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.section) {
            BackupSnapshotSection(summary: summary)

            BackupExportSection(exportAction: exportAction)

            BackupImportSection(
                chooseBackupAction: chooseBackupAction
            )

            if let preview {
                BackupImportPreviewSection(
                    preview: preview,
                    mergeAction: mergeAction,
                    replaceAction: replaceAction
                )
            }

            if let statusMessage {
                BackupStatusSection(message: statusMessage)
            }

            BackupResetSection(deleteEverythingAction: deleteEverythingAction)
        }
        .mhScreen()
    }
}
