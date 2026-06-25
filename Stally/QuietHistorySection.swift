//
//  QuietHistorySection.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import SwiftUI

struct QuietHistorySection: View {
    private enum Layout {
        static let gridVerticalPadding: CGFloat = 4
        static let latestMarkedDayLimit = 5
    }

    let history: ItemHistorySnapshot

    var body: some View {
        Section("Quiet History") {
            if history.markedDays.isEmpty {
                Text("No marks yet.")
                    .foregroundStyle(.secondary)
            } else {
                QuietHistoryGrid(markedDays: history.markedDays)
                    .padding(.vertical, Layout.gridVerticalPadding)

                LatestMarkedDays(days: Array(history.markedDays.prefix(Layout.latestMarkedDayLimit)))
            }
        }
    }
}
