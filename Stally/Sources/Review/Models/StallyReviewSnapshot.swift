import Foundation
import StallyLibrary

struct StallyReviewSnapshot {
    let summary: ItemReviewSummary
    let snapshotsByID: [UUID: ItemReviewSnapshot]
    let untouchedItems: [Item]
    let dormantItems: [Item]
    let recoveryCandidateItems: [Item]

    var syncKey: String {
        [
            untouchedItems.map(\.id.uuidString).joined(separator: ","),
            dormantItems.map(\.id.uuidString).joined(separator: ","),
            recoveryCandidateItems.map(\.id.uuidString).joined(separator: ","),
            String(summary.totalReviewCount),
        ].joined(separator: "#")
    }
}

enum StallyReviewSnapshotBuilder {
    static func build(
        items: [Item],
        preferences: StallyReviewPreferences
    ) -> StallyReviewSnapshot {
        let policy = preferences.policy
        let activeItems = ItemInsightsCalculator.homeSort(
            items: ItemInsightsCalculator.activeItems(from: items)
        )
        let archivedItems = ItemInsightsCalculator.archivedItems(from: items)
        let snapshots = ItemReviewCalculator.snapshots(
            from: items,
            policy: policy
        )

        return .init(
            summary: ItemReviewCalculator.summary(
                from: items,
                policy: policy
            ),
            snapshotsByID: Dictionary(
                uniqueKeysWithValues: snapshots.map { snapshot in
                    (snapshot.itemID, snapshot)
                }
            ),
            untouchedItems: ItemReviewCalculator.items(
                from: activeItems,
                with: .untouched,
                policy: policy
            ),
            dormantItems: ItemReviewCalculator.items(
                from: activeItems,
                with: .dormant,
                policy: policy
            ),
            recoveryCandidateItems: ItemReviewCalculator.items(
                from: archivedItems,
                with: .recoveryCandidate,
                policy: policy
            )
        )
    }
}
