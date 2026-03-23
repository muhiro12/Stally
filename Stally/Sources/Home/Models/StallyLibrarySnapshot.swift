import Foundation
import StallyLibrary

// swiftlint:disable file_types_order one_declaration_per_file multiline_function_chains
struct StallyLibrarySnapshot {
    let activeItems: [Item]
    let reviewSummary: ItemReviewSummary
    let archiveSummary: ItemInsightsCalculator.ArchiveCollectionSummary
    let insightsActivitySummary: CollectionActivitySummary
    let insightsStreakSummary: CollectionStreakSummary
    let insightsHealthSummary: CollectionHealthSummary

    var syncKey: String {
        let activeItemSignature = activeItems.map { item in
            [
                item.id.uuidString,
                String(item.updatedAt.timeIntervalSinceReferenceDate),
                String(item.marks.count),
            ].joined(separator: "|")
        }.joined(separator: ",")

        return [
            activeItemSignature,
            String(reviewSummary.totalReviewCount),
            String(archiveSummary.totalItems),
            String(insightsActivitySummary.totalMarks),
            String(insightsStreakSummary.bestStreakDays),
            String(insightsHealthSummary.totalItems),
        ].joined(separator: "#")
    }
}

enum StallyLibrarySnapshotBuilder {
    static func build(
        items: [Item],
        reviewPreferences: StallyReviewPreferences
    ) -> StallyLibrarySnapshot {
        let activeItems = ItemInsightsCalculator.homeSort(
            items: ItemInsightsCalculator.activeItems(from: items)
        )

        return .init(
            activeItems: activeItems,
            reviewSummary: ItemReviewCalculator.summary(
                from: items,
                policy: reviewPreferences.policy
            ),
            archiveSummary: ItemInsightsCalculator.archiveSummary(
                from: ItemInsightsCalculator.archivedItems(from: items)
            ),
            insightsActivitySummary: ItemInsightsCalculator.activitySummary(
                from: items,
                range: .last30Days
            ),
            insightsStreakSummary: ItemInsightsCalculator.streakSummary(
                from: items,
                range: .last30Days
            ),
            insightsHealthSummary: ItemInsightsCalculator.healthSummary(
                from: items,
                range: .last30Days,
                includeArchivedItems: false
            )
        )
    }
}
// swiftlint:enable file_types_order one_declaration_per_file multiline_function_chains
