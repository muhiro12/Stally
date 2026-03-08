import MHUI
import StallyLibrary
import SwiftUI

struct StallyInsightsCadenceSection: View {
    let streakSummary: CollectionStreakSummary
    let cadenceSummary: CollectionCadenceSummary
    let usesCompactLayout: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Consistency")
                .mhRowTitle()

            Text("A compact read on streak strength, weekly steadiness, and how much activity is concentrated on weekends.")
                .mhRowSupporting()

            StallyMetricGrid(
                metrics: metrics,
                usesCompactLayout: usesCompactLayout
            )
        }
        .mhSection(title: Text("Consistency"))
    }
}

private extension StallyInsightsCadenceSection {
    var metrics: [StallyMetricGrid.Metric] {
        [
            .init(title: "Current Streak", value: "\(streakSummary.currentStreakDays)"),
            .init(title: "Best Streak", value: "\(streakSummary.bestStreakDays)"),
            .init(title: "Idle Gap", value: "\(streakSummary.longestIdleGapDays)"),
            .init(
                title: "Avg Marks / Week",
                value: cadenceSummary.averageMarksPerWeek.formatted(
                    .number.precision(.fractionLength(1))
                )
            ),
            .init(title: "Active Weeks", value: "\(cadenceSummary.activeWeeks)"),
            .init(
                title: "Weekend Share",
                value: cadenceSummary.weekendShareOfMarks.formatted(
                    .percent.precision(.fractionLength(0))
                )
            )
        ]
    }
}
