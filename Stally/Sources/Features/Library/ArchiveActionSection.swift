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
        Section("Archive") {
            if isArchived {
                Button(action: moveBackAction) {
                    Label("Move Back to Library", systemImage: "tray.and.arrow.up")
                }
                .buttonStyle(.mhPrimary)

                Text("Archived items wait until you move them back to Library.")
                    .mhSectionFooterText()
            } else {
                Button(action: archiveAction) {
                    Label("Archive Item", systemImage: "archivebox")
                }
                .buttonStyle(.mhQuiet)

                Text("Past favorites can stay nearby without crowding the main list.")
                    .mhSectionFooterText()
            }
        }
    }
}
