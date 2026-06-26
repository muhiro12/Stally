//
//  InsightItemSummaryRow.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHUI
import SwiftUI

struct InsightItemSummaryRow: View {
    let summary: ItemInsightSummary

    var body: some View {
        VStack(alignment: .leading) {
            Text(summary.item.name)
                .mhRowTitle()

            HStack {
                Text(summary.item.category.title)

                Text("\(summary.marksInRange, format: .number) marks")

                if let lastMarkedDay = summary.lastMarkedDay {
                    Text(lastMarkedDay, format: .dateTime.month().day())
                }
            }
            .mhRowOverline()
        }
        .mhRow()
    }
}
