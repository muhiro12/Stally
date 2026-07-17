//
//  BackupImportSection.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHUI
import SwiftUI

struct BackupImportSection: View {
    let chooseBackupAction: () -> Void

    var body: some View {
        MHActionGroup {
            Button(action: chooseBackupAction) {
                Label("Choose Backup File", systemImage: "doc.badge.plus")
            }
            .buttonStyle(.mhSecondary)
        }
        .mhSection("Import Tools")
    }
}
