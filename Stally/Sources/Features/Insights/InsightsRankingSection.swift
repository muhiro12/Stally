//
//  InsightsRankingSection.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHUI
import SwiftUI

struct InsightsRankingSection: View {
    let title: LocalizedStringResource
    let emptyMessage: LocalizedStringResource
    let summaries: [ItemInsightSummary]

    var body: some View {
        MHGroupedRows {
            if summaries.isEmpty {
                Text(emptyMessage)
                    .mhRowSupporting()
            } else {
                ForEach(summaries, id: \.item.uuid) { summary in
                    NavigationLink(
                        value: StallyNavigationView.DetailRoute.item(summary.item.uuid)
                    ) {
                        InsightItemSummaryRow(summary: summary)
                    }
                }
            }
        }
        .mhSection(title: Text(title))
    }
}
