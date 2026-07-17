//
//  HistoryAdjustmentActionSection.swift
//  Stally
//
//  Created by Codex on 2026/07/12.
//

import MHUI
import SwiftUI

struct HistoryAdjustmentActionSection: View {
    let isMarked: Bool
    let isSelectionValid: Bool
    let addAction: () -> Void
    let removeAction: () -> Void

    var body: some View {
        Section {
            LabeledContent("Status") {
                if isMarked {
                    Text("Marked")
                        .mhBadge(style: .accent)
                } else {
                    Text("Not marked")
                        .mhBadge(style: .neutral)
                }
            }

            if isMarked {
                Button(role: .destructive, action: removeAction) {
                    Label("Remove Mark", systemImage: "minus.circle")
                }
                .buttonStyle(.mhDestructive)
                .disabled(!isSelectionValid)
            } else {
                Button(action: addAction) {
                    Label("Add Mark", systemImage: "plus.circle")
                }
                .buttonStyle(.mhPrimary)
                .disabled(!isSelectionValid)
            }
        }
    }
}
