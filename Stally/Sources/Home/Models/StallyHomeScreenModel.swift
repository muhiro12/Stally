import Foundation
import Observation
import StallyLibrary

@Observable
final class StallyHomeScreenModel {
    struct QuickFilterOption: Identifiable, Hashable {
        let id: String
        let title: String
        let filter: ItemListQuery.QuickFilter?
    }

    enum UtilityDestination: String, Identifiable {
        case review
        case insights
        case archive
        case backup

        var id: String {
            rawValue
        }
    }

    struct UtilityPanel: Identifiable {
        let destination: UtilityDestination
        let title: String
        let value: String
        let supporting: String
        let metrics: [StallyMetricGrid.Metric]

        var id: UtilityDestination {
            destination
        }
    }

    var query = ItemListQuery()
    private(set) var snapshot: StallyLibrarySnapshot

    init(
        snapshot: StallyLibrarySnapshot
    ) {
        self.snapshot = snapshot
    }

    func update(
        snapshot: StallyLibrarySnapshot
    ) {
        self.snapshot = snapshot
    }

    func selectQuickFilter(
        _ filter: ItemListQuery.QuickFilter?
    ) {
        query.quickFilter = filter
    }

    var displayedItems: [Item] {
        ItemInsightsCalculator.items(
            from: snapshot.activeItems,
            matching: query,
            kind: .active
        )
    }

    var displayedSummary: ItemInsightsCalculator.ActiveCollectionSummary {
        ItemInsightsCalculator.activeSummary(
            from: displayedItems
        )
    }

    var recentItems: [Item] {
        snapshot.recentItems
    }

    var availableQuickFilters: [QuickFilterOption] {
        [
            .init(
                id: "all",
                title: StallyLocalization.string("All"),
                filter: nil
            ),
            .init(
                id: "openToday",
                title: StallyLocalization.string("Open Today"),
                filter: .unmarkedOnReferenceDay
            ),
            .init(
                id: "markedToday",
                title: StallyLocalization.string("Marked Today"),
                filter: .markedOnReferenceDay
            ),
            .init(
                id: "neverMarked",
                title: StallyLocalization.string("Never Marked"),
                filter: .withoutHistory
            ),
        ]
    }

    var homeSummaryMetrics: [StallyMetricGrid.Metric] {
        [
            .init(
                title: StallyLocalization.string("Items"),
                value: "\(displayedSummary.totalItems)"
            ),
            .init(
                title: StallyLocalization.string("Marked Today"),
                value: "\(displayedSummary.markedTodayCount)"
            ),
            .init(
                title: StallyLocalization.string("Untouched"),
                value: "\(displayedSummary.neverMarkedCount)"
            ),
            .init(
                title: StallyLocalization.string("Total Marks"),
                value: "\(displayedSummary.totalMarks)"
            ),
        ]
    }

    var utilityPanels: [UtilityPanel] {
        [
            .init(
                destination: .review,
                title: "Review",
                value: "\(snapshot.reviewSummary.totalReviewCount)",
                supporting: "Untouched, dormant, and recovery candidates collected in one lane.",
                metrics: [
                    .init(
                        title: StallyLocalization.string("First Mark"),
                        value: "\(snapshot.reviewSummary.untouchedCount)"
                    ),
                    .init(
                        title: StallyLocalization.string("Dormant"),
                        value: "\(snapshot.reviewSummary.dormantCount)"
                    ),
                    .init(
                        title: StallyLocalization.string("Recovery"),
                        value: "\(snapshot.reviewSummary.recoveryCandidateCount)"
                    ),
                ]
            ),
            .init(
                destination: .insights,
                title: "Insights",
                value: "\(snapshot.insightsActivitySummary.totalMarks)",
                supporting: "Open the last 30 days as patterns, cadence, and next moves.",
                metrics: [
                    .init(
                        title: StallyLocalization.string("Marks (30d)"),
                        value: "\(snapshot.insightsActivitySummary.totalMarks)"
                    ),
                    .init(
                        title: StallyLocalization.string("Active Days"),
                        value: "\(snapshot.insightsActivitySummary.activeDays)"
                    ),
                    .init(
                        title: StallyLocalization.string("Best Streak"),
                        value: "\(snapshot.insightsStreakSummary.bestStreakDays)"
                    ),
                    .init(
                        title: StallyLocalization.string("Items"),
                        value: "\(snapshot.insightsHealthSummary.totalItems)"
                    ),
                ]
            ),
            .init(
                destination: .archive,
                title: "Archive",
                value: "\(snapshot.archiveSummary.totalItems)",
                supporting: "Keep past favorites nearby without letting them crowd today.",
                metrics: [
                    .init(
                        title: StallyLocalization.string("Items"),
                        value: "\(snapshot.archiveSummary.totalItems)"
                    ),
                    .init(
                        title: StallyLocalization.string("Saved Marks"),
                        value: "\(snapshot.archiveSummary.totalMarks)"
                    ),
                ]
            ),
            .init(
                destination: .backup,
                title: "Backup",
                value: "\(snapshot.activeItems.count + snapshot.archiveSummary.totalItems)",
                supporting: "Export or restore the current collection before making bigger changes.",
                metrics: [
                    .init(
                        title: StallyLocalization.string("Active"),
                        value: "\(snapshot.activeItems.count)"
                    ),
                    .init(
                        title: StallyLocalization.string("Archived"),
                        value: "\(snapshot.archiveSummary.totalItems)"
                    ),
                ]
            ),
        ]
    }
}
