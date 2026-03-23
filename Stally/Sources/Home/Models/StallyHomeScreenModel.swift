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

    var query = ItemListQuery()
    private(set) var snapshot: StallyLibrarySnapshot

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

    var totalLibraryMarks: Int {
        ItemInsightsCalculator.activeSummary(
            from: snapshot.activeItems
        ).totalMarks + snapshot.archiveSummary.totalMarks
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
}
