//
//  BackupSafetySection.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import SwiftUI

struct BackupSafetySection: View {
    var body: some View {
        Section("Safety") {
            Text("Export before higher-risk changes.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Keep one recent export before you try any replace-style restore.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Backup files are meant for your own archive and transfer workflow.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("They are not for syncing between multiple devices at once.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
