//
//  InsightItemSummaryRow.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHUI
import SwiftUI

struct InsightItemSummaryRow: View {
    @Environment(\.timeZone)
    private var timeZone

    let summary: ItemInsightSummary

    var body: some View {
        VStack(alignment: .leading) {
            Text(summary.item.name)
                .mhRowTitle()

            HStack {
                Text(summary.item.category.title)

                Text("\(summary.marksInRange) marks")

                if let lastMarkedDay = summary.lastMarkedDay {
                    if let date = lastMarkedDay.date(in: timeZone) {
                        Text(date, format: .dateTime.month().day())
                    } else {
                        Text(verbatim: lastMarkedDay.iso8601Date)
                    }
                }
            }
            .mhRowOverline()
        }
        .mhRow()
    }
}
