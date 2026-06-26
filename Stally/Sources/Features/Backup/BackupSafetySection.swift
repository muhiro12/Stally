//
//  BackupSafetySection.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHUI
import SwiftUI

struct BackupSafetySection: View {
    var body: some View {
        Section("Safety") {
            Text("Export before higher-risk changes.")
                .mhRowSupporting()

            Text("Keep one recent export before you try any replace-style restore.")
                .mhRowSupporting()

            Text("Backup files are meant for your own archive and transfer workflow.")
                .mhRowSupporting()

            Text("They are not for syncing between multiple devices at once.")
                .mhRowSupporting()
        }
    }
}
