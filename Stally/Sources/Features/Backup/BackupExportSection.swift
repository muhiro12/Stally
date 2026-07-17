//
//  BackupExportSection.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHUI
import SwiftUI
import TipKit

struct BackupExportSection: View {
    private let exportTip = BackupExportTip()

    let exportAction: () -> Void

    var body: some View {
        MHActionGroup {
            Button(action: exportBackup) {
                Label("Export Backup", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.mhPrimary)
            .popoverTip(exportTip, arrowEdge: .top)
        }
        .mhSection("Export Tools")
    }

    private func exportBackup() {
        exportAction()
        exportTip.invalidate(reason: .actionPerformed)
    }
}
