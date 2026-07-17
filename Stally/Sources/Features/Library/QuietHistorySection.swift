//
//  QuietHistorySection.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import MHUI
import SwiftUI

struct QuietHistorySection: View {
    private enum Layout {
        static let gridVerticalPadding: CGFloat = 4
        static let latestMarkedDayLimit = 5
    }

    let history: ItemHistorySnapshot

    var body: some View {
        MHGroupedRows {
            if history.markedDays.isEmpty {
                Text("No marks yet.")
                    .mhRowSupporting()
            } else {
                QuietHistoryGrid(markedDays: history.markedDays)
                    .padding(.vertical, Layout.gridVerticalPadding)

                LatestMarkedDays(days: Array(history.markedDays.prefix(Layout.latestMarkedDayLimit)))
            }
        }
        .mhSection("Quiet History")
    }
}
