import Foundation
import StallyLibrary

enum StallyInsightsReportBuilder {
    // swiftlint:disable:next function_parameter_count
    static func build(
        range: ItemInsightsRange,
        includesArchivedItems: Bool,
        activitySummary: CollectionActivitySummary,
        streakSummary: CollectionStreakSummary,
        healthSummary: CollectionHealthSummary,
        topRankings: [CollectionItemRanking],
        quietRankings: [CollectionItemRanking],
        itemsByID: [UUID: Item]
    ) -> String {
        let noteCoverage = healthSummary.noteCoverage.formatted(
            .percent.precision(.fractionLength(0))
        )
        let photoCoverage = healthSummary.photoCoverage.formatted(
            .percent.precision(.fractionLength(0))
        )
        let scopeTitle = includesArchivedItems
            ? StallyLocalization.string("All items")
            : StallyLocalization.string("Active items only")
        let topTitle = rankingTitle(
            for: topRankings.first,
            itemsByID: itemsByID
        )
        let quietTitle = rankingTitle(
            for: quietRankings.first,
            itemsByID: itemsByID
        )

        return """
        \(StallyLocalization.string("Stally Insights"))
        \(StallyLocalization.format("Range: %@", range.title))
        \(StallyLocalization.format("Scope: %@", scopeTitle))

        \(StallyLocalization.string("Activity"))
        - \(StallyLocalization.format("Marks: %lld", activitySummary.totalMarks))
        - \(StallyLocalization.format("Active days: %lld", activitySummary.activeDays))
        - \(StallyLocalization.format("Unique items: %lld", activitySummary.uniqueMarkedItems))

        \(StallyLocalization.string("Consistency"))
        - \(StallyLocalization.format("Current streak: %lld", streakSummary.currentStreakDays))
        - \(StallyLocalization.format("Best streak: %lld", streakSummary.bestStreakDays))
        - \(StallyLocalization.format("Longest idle gap: %lld", streakSummary.longestIdleGapDays))

        \(StallyLocalization.string("Collection Health"))
        - \(StallyLocalization.format("Items: %lld", healthSummary.totalItems))
        - \(StallyLocalization.format("With history: %lld", healthSummary.itemsWithHistory))
        - \(StallyLocalization.format("Note coverage: %@", noteCoverage))
        - \(StallyLocalization.format("Photo coverage: %@", photoCoverage))

        \(StallyLocalization.string("Spotlight"))
        - \(StallyLocalization.format("Top item: %@", topTitle))
        - \(StallyLocalization.format("Quiet item: %@", quietTitle))
        """
    }

    private static func rankingTitle(
        for ranking: CollectionItemRanking?,
        itemsByID: [UUID: Item]
    ) -> String {
        guard let ranking else {
            return StallyLocalization.string("None")
        }

        return itemsByID[ranking.itemID]?.name
            ?? StallyLocalization.string("Unknown Item")
    }
}
