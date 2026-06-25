//
//  InsightItemSummaryRow.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import SwiftUI

struct InsightItemSummaryRow: View {
    let summary: ItemInsightSummary

    var body: some View {
        VStack(alignment: .leading) {
            Text(summary.item.name)
                .font(.headline)

            HStack {
                Text(summary.item.category.title)

                Text("\(summary.marksInRange, format: .number) marks")

                if let lastMarkedDay = summary.lastMarkedDay {
                    Text(lastMarkedDay, format: .dateTime.month().day())
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }
}
