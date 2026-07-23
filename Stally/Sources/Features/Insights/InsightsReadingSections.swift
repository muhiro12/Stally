//
//  InsightsReadingSections.swift
//  Stally
//
//  Created by Codex on 2026/07/18.
//

import MHUI
import SwiftUI

struct InsightsReadingSections: View {
    @Environment(\.mhTheme)
    private var theme

    let snapshot: InsightsSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.section) {
            InsightsRhythmSection(
                weekdayActivity: snapshot.weekdayActivity,
                monthlyActivity: snapshot.monthlyActivity
            )

            InsightsCategoryShareSection(categoryShares: snapshot.categoryShares)

            InsightsRankingSection(
                title: "Top Items",
                emptyMessage: "No activity in this window yet.",
                summaries: snapshot.topItems
            )

            InsightsRankingSection(
                title: "Quiet Items",
                emptyMessage: "No quiet items in this window yet.",
                summaries: snapshot.quietItems
            )
        }
    }
}
