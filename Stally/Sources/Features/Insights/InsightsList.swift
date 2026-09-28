//
//  InsightsList.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHPlatform
import MHUI
import SwiftUI

struct InsightsList: View {
    @AppStorage(\.isSubscribeOn)
    private var isSubscribeOn
    @Environment(\.mhTheme)
    private var theme

    let snapshot: InsightsSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.section) {
            InsightsSummary(
                totalMarks: snapshot.totalMarks,
                rangeTitle: snapshot.options.range.title,
                includesArchivedItems: snapshot.options.includesArchivedItems,
                choiceItemCount: snapshot.choiceItemCount,
                hasHistoryConflict: snapshot.nonMarkHistoryConflictCount > 0
            )

            InsightsHighlightsSection(snapshot: snapshot)

            Text("Choice readings include only items that record Marks. Context coverage includes all scoped items.")
                .mhTextStyle(.supporting, colorRole: .secondaryText)

            InsightsReadingSections(snapshot: snapshot)

            InsightsReportSection(
                report: InsightsReportOperations.report(for: snapshot)
            )

            if !isSubscribeOn {
                StallyAdvertisementSection(layout: .media)
            }

            InsightsRecommendationsSection(recommendations: snapshot.recommendations)
        }
        .mhScreen("Insights")
    }
}
