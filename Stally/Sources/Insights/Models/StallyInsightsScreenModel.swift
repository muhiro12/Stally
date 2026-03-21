import Foundation
import Observation
import StallyLibrary
import SwiftUI

@Observable
final class StallyInsightsScreenModel {
    private(set) var snapshot: StallyInsightsSnapshot

    var overviewMetrics: [StallyMetricGrid.Metric] {
        [
            .init(
                title: StallyLocalization.string("Marks"),
                value: "\(snapshot.activitySummary.totalMarks)"
            ),
            .init(
                title: StallyLocalization.string("Active Days"),
                value: "\(snapshot.activitySummary.activeDays)"
            ),
            .init(
                title: StallyLocalization.string("Best Streak"),
                value: "\(snapshot.streakSummary.bestStreakDays)"
            ),
            .init(
                title: StallyLocalization.string("Items"),
                value: "\(snapshot.healthSummary.totalItems)"
            ),
        ]
    }

    var activityMetrics: [StallyMetricGrid.Metric] {
        [
            .init(
                title: StallyLocalization.string("Unique Items"),
                value: "\(snapshot.activitySummary.uniqueMarkedItems)"
            ),
            .init(
                title: StallyLocalization.string("Categories"),
                value: "\(snapshot.activitySummary.uniqueMarkedCategories)"
            ),
            .init(
                title: StallyLocalization.string("Avg / Active Day"),
                value: snapshot.activitySummary.averageMarksPerActiveDay.formatted(
                    .number.precision(.fractionLength(1))
                )
            ),
            .init(
                title: StallyLocalization.string("Busiest Day"),
                value: busiestDayValue
            ),
        ]
    }

    var consistencyMetrics: [StallyMetricGrid.Metric] {
        [
            .init(
                title: StallyLocalization.string("Current Streak"),
                value: "\(snapshot.streakSummary.currentStreakDays)"
            ),
            .init(
                title: StallyLocalization.string("Best Streak"),
                value: "\(snapshot.streakSummary.bestStreakDays)"
            ),
            .init(
                title: StallyLocalization.string("Idle Gap"),
                value: "\(snapshot.streakSummary.longestIdleGapDays)"
            ),
            .init(
                title: StallyLocalization.string("Avg Marks / Week"),
                value: snapshot.cadenceSummary.averageMarksPerWeek.formatted(
                    .number.precision(.fractionLength(1))
                )
            ),
            .init(
                title: StallyLocalization.string("Active Weeks"),
                value: "\(snapshot.cadenceSummary.activeWeeks)"
            ),
            .init(
                title: StallyLocalization.string("Weekend Share"),
                value: snapshot.cadenceSummary.weekendShareOfMarks.formatted(
                    .percent.precision(.fractionLength(0))
                )
            ),
        ]
    }

    var busiestDayValue: String {
        guard let busiestDay = snapshot.activitySummary.busiestDay else {
            return StallyLocalization.string("None")
        }

        return StallyLocalization.format(
            "%1$lld on %2$@",
            busiestDay.markCount,
            busiestDay.date.formatted(date: .abbreviated, time: .omitted)
        )
    }

    init(
        snapshot: StallyInsightsSnapshot
    ) {
        self.snapshot = snapshot
    }

    func barHeight(
        for day: CollectionActivityDay
    ) -> CGFloat {
        let maximumMarks = max(snapshot.activityDays.map(\.markCount).max() ?? 0, 1)
        let normalized = CGFloat(day.markCount) / CGFloat(maximumMarks)

        return max(14, normalized * 104)
    }

    func shouldShowLabel(
        for day: CollectionActivityDay
    ) -> Bool {
        guard let index = snapshot.activityDays.firstIndex(where: { $0.date == day.date }) else {
            return false
        }

        if index == .zero || index == snapshot.activityDays.count - 1 {
            return true
        }

        let divisor = max(snapshot.activityDays.count / 4, 1)
        return index.isMultiple(of: divisor)
    }

    func update(
        snapshot: StallyInsightsSnapshot
    ) {
        self.snapshot = snapshot
    }
}
