//
//  ArchiveActionSection.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHUI
import SwiftUI

struct ArchiveActionSection: View {
    let isArchived: Bool
    let archiveAction: () -> Void
    let moveBackAction: () -> Void

    var body: some View {
        Section {
            if isArchived {
                Button(action: moveBackAction) {
                    Label("Move Back to Library", systemImage: "tray.and.arrow.up")
                }
                .buttonStyle(.mhPrimary)
            } else {
                Button(action: archiveAction) {
                    Label("Archive Item", systemImage: "archivebox")
                }
                .buttonStyle(.mhQuiet)
            }
        } header: {
            StallySectionHeader("Archive")
        }
    }
}
