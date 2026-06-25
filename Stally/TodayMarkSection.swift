//
//  TodayMarkSection.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

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
            } else {
                Button(action: markAction) {
                    Label("Mark Today", systemImage: "checkmark.circle")
                }
                .buttonStyle(.borderedProminent)
            }

            Text("One mark is enough for today.")
                .foregroundStyle(.secondary)
        }
    }
}
