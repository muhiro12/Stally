//
//  BackupList.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import SwiftUI

struct BackupList: View {
    let summary: BackupCollectionSummary
    let preview: BackupPreview?
    let statusMessage: String?
    let exportAction: () -> Void
    let chooseBackupAction: () -> Void
    let mergeAction: () -> Void
    let replaceAction: () -> Void
    let deleteEverythingAction: () -> Void

    var body: some View {
        List {
            BackupSnapshotSection(summary: summary)

            BackupExportSection(exportAction: exportAction)

            BackupImportSection(
                preview: preview,
                chooseBackupAction: chooseBackupAction,
                mergeAction: mergeAction,
                replaceAction: replaceAction
            )

            BackupResetSection(deleteEverythingAction: deleteEverythingAction)

            if let statusMessage {
                BackupStatusSection(message: statusMessage)
            }
        }
        .stallyListChrome()
    }
}
