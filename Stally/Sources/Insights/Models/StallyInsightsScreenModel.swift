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
