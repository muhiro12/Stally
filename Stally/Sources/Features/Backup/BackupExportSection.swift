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
        Section("Export Tools") {
            Button(action: exportBackup) {
                Label("Export Backup", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.mhSecondary)
            .popoverTip(exportTip, arrowEdge: .top)
        }
    }

    private func exportBackup() {
        exportAction()
        exportTip.invalidate(reason: .actionPerformed)
    }
}
