import Foundation
import Observation
import StallyLibrary

@Observable
final class StallyArchiveScreenModel {
    struct QuickFilterOption: Identifiable, Hashable {
        let id: String
        let title: String
        let filter: ItemListQuery.QuickFilter?
    }

    var query = ItemListQuery()
    private(set) var snapshot: StallyArchiveSnapshot

    init(
        snapshot: StallyArchiveSnapshot
    ) {
        self.snapshot = snapshot
    }

    func update(
        snapshot: StallyArchiveSnapshot
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
            from: snapshot.archivedItems,
            matching: query,
            kind: .archived
        )
    }

    var availableQuickFilters: [QuickFilterOption] {
        [
            .init(
                id: "all",
                title: StallyLocalization.string("All"),
                filter: nil
            ),
            .init(
                id: "withHistory",
                title: StallyLocalization.string("With History"),
                filter: .withHistory
            ),
            .init(
                id: "withoutHistory",
                title: StallyLocalization.string("Without History"),
                filter: .withoutHistory
            ),
        ]
    }

    var archiveMetrics: [StallyMetricGrid.Metric] {
        [
            .init(
                title: StallyLocalization.string("Items"),
                value: "\(snapshot.summary.totalItems)"
            ),
            .init(
                title: StallyLocalization.string("With History"),
                value: "\(snapshot.summary.itemsWithMarksCount)"
            ),
            .init(
                title: StallyLocalization.string("Saved Marks"),
                value: "\(snapshot.summary.totalMarks)"
            ),
            .init(
                title: StallyLocalization.string("Latest Archive"),
                value: snapshot.summary.lastArchivedAt?.formatted(
                    date: .abbreviated,
                    time: .omitted
                ) ?? StallyLocalization.string("None")
            ),
        ]
    }
}
