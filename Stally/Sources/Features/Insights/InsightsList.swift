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
    @Binding var selectedRange: InsightsRange
    @Binding var includesArchivedItems: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.section) {
            InsightsSummary(
                totalMarks: snapshot.totalMarks,
                rangeTitle: snapshot.options.range.title
            )

            InsightsScopeSection(
                selectedRange: $selectedRange,
                includesArchivedItems: $includesArchivedItems
            )

            InsightsReportSection(
                report: InsightsReportOperations.report(for: snapshot)
            )

            InsightsReadingSections(snapshot: snapshot)

            if !isSubscribeOn {
                StallyAdvertisementSection(size: .medium)
            }

            InsightsRecommendationsSection(recommendations: snapshot.recommendations)
        }
        .mhScreen()
    }
}
