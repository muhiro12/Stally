import Foundation
import StallyLibrary

enum StallyInsightsReportBuilder {
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
        let scopeTitle = includesArchivedItems
            ? "All items"
            : "Active items only"
        let topTitle = rankingTitle(
            for: topRankings.first,
            itemsByID: itemsByID
        )
        let quietTitle = rankingTitle(
            for: quietRankings.first,
            itemsByID: itemsByID
        )

        return """
        Stally Insights
        Range: \(range.title)
        Scope: \(scopeTitle)

        Activity
        - Marks: \(activitySummary.totalMarks)
        - Active days: \(activitySummary.activeDays)
        - Unique items: \(activitySummary.uniqueMarkedItems)

        Consistency
        - Current streak: \(streakSummary.currentStreakDays)
        - Best streak: \(streakSummary.bestStreakDays)
        - Longest idle gap: \(streakSummary.longestIdleGapDays)

        Collection Health
        - Items: \(healthSummary.totalItems)
        - With history: \(healthSummary.itemsWithHistory)
        - Note coverage: \(healthSummary.noteCoverage.formatted(.percent.precision(.fractionLength(0))))
        - Photo coverage: \(healthSummary.photoCoverage.formatted(.percent.precision(.fractionLength(0))))

        Spotlight
        - Top item: \(topTitle)
        - Quiet item: \(quietTitle)
        """
    }

    private static func rankingTitle(
        for ranking: CollectionItemRanking?,
        itemsByID: [UUID: Item]
    ) -> String {
        guard let ranking else {
            return "None"
        }

        return itemsByID[ranking.itemID]?.name ?? "Unknown Item"
    }
}
