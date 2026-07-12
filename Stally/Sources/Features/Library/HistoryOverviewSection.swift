//
//  HistoryOverviewSection.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import MHUI
import SwiftUI

struct HistoryOverviewSection: View {
    @Environment(\.timeZone)
    private var timeZone

    let history: ItemHistorySnapshot

    var body: some View {
        Section("Overview") {
            LabeledContent("Total marks") {
                Text(history.totalMarks, format: .number)
            }

            LabeledContent("Last marked") {
                lastMarkedValue
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
                        .mhTextStyle(.body, colorRole: .secondaryText)
                }
            }
        }
        .labeledContentStyle(.mhKeyValue)
    }

    @ViewBuilder private var lastMarkedValue: some View {
        if let lastMarkedDay = history.lastMarkedDay {
            if let date = lastMarkedDay.date(in: timeZone) {
                Text(date, format: .dateTime.month().day().year())
            } else {
                Text(verbatim: lastMarkedDay.iso8601Date)
            }
        } else {
            Text("Not yet")
                .mhTextStyle(.body, colorRole: .secondaryText)
        }
    }
}
