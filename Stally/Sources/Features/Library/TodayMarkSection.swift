//
//  TodayMarkSection.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import MHUI
import SwiftUI
import TipKit

struct TodayMarkSection: View {
    private let markTodayTip = MarkTodayTip()

    let isMarkedToday: Bool
    let markAction: () -> Void
    let undoAction: () -> Void

    var body: some View {
        Section {
            if isMarkedToday {
                Button(action: undoAction) {
                    Label("Undo Today's Mark", systemImage: "arrow.uturn.backward")
                }
                .buttonStyle(.mhQuiet)
            } else {
                Button(action: markToday) {
                    Label("Mark Today", systemImage: "checkmark.circle")
                }
                .buttonStyle(.mhPrimary)
                .popoverTip(markTodayTip, arrowEdge: .top)
            }
        } header: {
            StallySectionHeader("Actions")
        }
    }

    private func markToday() {
        markAction()
        markTodayTip.invalidate(reason: .actionPerformed)
    }
}
