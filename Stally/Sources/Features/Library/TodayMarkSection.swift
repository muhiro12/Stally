//
//  TodayMarkSection.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import MHUI
import SwiftUI

struct TodayMarkSection: View {
    let isMarkedToday: Bool
    let markAction: () -> Void
    let undoAction: () -> Void

    var body: some View {
        Section("Actions") {
            if isMarkedToday {
                Button(action: undoAction) {
                    Label("Undo Today's Mark", systemImage: "arrow.uturn.backward")
                }
                .buttonStyle(.mhQuiet)
            } else {
                Button(action: markAction) {
                    Label("Mark Today", systemImage: "checkmark.circle")
                }
                .buttonStyle(.mhPrimary)
            }

            Text("One mark is enough for today.")
                .mhSectionFooterText()
        }
    }
}
