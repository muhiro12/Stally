//
//  HistoryOverviewSection.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import SwiftUI

struct HistoryOverviewSection: View {
    let history: ItemHistorySnapshot

    var body: some View {
        Section("Overview") {
            LabeledContent("Total marks") {
                Text(history.totalMarks, format: .number)
            }

            LabeledContent("Last marked") {
                if let lastMarkedDay = history.lastMarkedDay {
                    Text(lastMarkedDay, format: .dateTime.month().day().year())
                } else {
                    Text("Not yet")
                        .foregroundStyle(.secondary)
                }
            }

            LabeledContent("Marks (30d)") {
                Text(history.marksInLast30Days, format: .number)
            }

            LabeledContent("Marks (90d)") {
                Text(history.marksInLast90Days, format: .number)
            }

            LabeledContent("Months Used") {
                Text(history.monthsUsed, format: .number)
            }

            LabeledContent("Days Since Last") {
                if let daysSinceLastMark = history.daysSinceLastMark {
                    Text(daysSinceLastMark, format: .number)
                } else {
                    Text("Not yet")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
