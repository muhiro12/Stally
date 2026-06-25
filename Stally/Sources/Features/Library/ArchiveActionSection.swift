//
//  ArchiveActionSection.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

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
                .buttonStyle(.borderedProminent)

                Text("Archived items wait until you move them back to Library.")
                    .foregroundStyle(.secondary)
            } else {
                Button(action: archiveAction) {
                    Label("Archive Item", systemImage: "archivebox")
                }

                Text("Past favorites can stay nearby without crowding the main list.")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
