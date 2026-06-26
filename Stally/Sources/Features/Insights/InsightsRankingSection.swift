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
        Section(title) {
            if summaries.isEmpty {
                Text(emptyMessage)
                    .mhRowSupporting()
            } else {
                ForEach(summaries, id: \.item.uuid) { summary in
                    NavigationLink {
                        ItemDetailView(item: summary.item)
                    } label: {
                        InsightItemSummaryRow(summary: summary)
                    }
                }
            }
        }
    }
}
