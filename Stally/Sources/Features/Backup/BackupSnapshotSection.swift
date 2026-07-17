//
//  BackupSnapshotSection.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHUI
import SwiftUI

struct BackupSnapshotSection: View {
    let summary: BackupCollectionSummary

    var body: some View {
        Section {
            LabeledContent("Items") {
                Text(summary.itemCount, format: .number)
            }

            LabeledContent("Archived") {
                Text(summary.archivedItemCount, format: .number)
            }

            LabeledContent("Marks") {
                Text(summary.markCount, format: .number)
            }
        } header: {
            MHSectionHeader("Backup Snapshot")
        }
    }
}
