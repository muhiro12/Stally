//
//  BackupImportSection.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHUI
import SwiftUI

struct BackupImportSection: View {
    let preview: BackupPreview?
    let chooseBackupAction: () -> Void
    let mergeAction: () -> Void
    let replaceAction: () -> Void

    var body: some View {
        Section("Import Tools") {
            Button(action: chooseBackupAction) {
                Label("Choose Backup File", systemImage: "doc.badge.plus")
            }
            .buttonStyle(.mhSecondary)

            if let preview {
                BackupPreviewRows(preview: preview)

                Button("Merge Into Library", action: mergeAction)
                    .disabled(!preview.canImport)
                    .buttonStyle(.mhPrimary)

                Button("Replace Library", role: .destructive, action: replaceAction)
                    .disabled(!preview.canImport)
                    .buttonStyle(.mhDestructive)
            }
        }
    }
}
