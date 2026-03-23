import Foundation
import Observation
import StallyLibrary

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

    func update(
        snapshot: StallyInsightsSnapshot
    ) {
        self.snapshot = snapshot
    }
}
