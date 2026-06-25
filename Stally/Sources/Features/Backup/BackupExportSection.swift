//
//  BackupExportSection.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import SwiftUI

struct BackupExportSection: View {
    let exportAction: () -> Void

    var body: some View {
        Section("Export Tools") {
            Button(action: exportAction) {
                Label("Export Backup", systemImage: "square.and.arrow.up")
            }
        }
    }
}
