import Foundation
import StallyLibrary

// swiftlint:disable file_types_order one_declaration_per_file function_body_length
struct StallyInsightsSnapshot {
    let range: ItemInsightsRange
    let includesArchivedItems: Bool
    let activitySummary: CollectionActivitySummary
    let activityDays: [CollectionActivityDay]
    let streakSummary: CollectionStreakSummary
    let cadenceSummary: CollectionCadenceSummary
    let healthSummary: CollectionHealthSummary
    let categorySummaries: [CollectionCategorySummary]
    let weekdaySummaries: [CollectionWeekdaySummary]
    let monthlySummaries: [CollectionMonthSummary]
    let topRankings: [CollectionItemRanking]
    let quietRankings: [CollectionItemRanking]
    let recommendations: [CollectionRecommendation]
    let itemsByID: [UUID: Item]
    let reportText: String

    var syncKey: String {
        [
            range.rawValue,
            includesArchivedItems ? "1" : "0",
            reportText,
        ].joined(separator: "#")
    }
}

enum StallyInsightsSnapshotBuilder {
    static func build(
        items: [Item],
        preferences: StallyInsightsPreferences
    ) -> StallyInsightsSnapshot {
        let range = preferences.defaultRange
        let includesArchivedItems = preferences.includesArchivedItems
        let activitySummary = ItemInsightsCalculator.activitySummary(
            from: items,
            range: range,
            includeArchivedItems: includesArchivedItems
        )
        let activityDays = ItemInsightsCalculator.activityDays(
            from: items,
            range: range,
            includeArchivedItems: includesArchivedItems
        )
        let streakSummary = ItemInsightsCalculator.streakSummary(
            from: items,
            range: range,
            includeArchivedItems: includesArchivedItems
        )
        let cadenceSummary = ItemInsightsCalculator.cadenceSummary(
            from: items,
            range: range,
            includeArchivedItems: includesArchivedItems
        )
        let healthSummary = ItemInsightsCalculator.healthSummary(
            from: items,
            range: range,
            includeArchivedItems: includesArchivedItems
        )
        let itemsByID = Dictionary(
            uniqueKeysWithValues: items.map { item in
                (item.id, item)
            }
        )
        let topRankings = ItemInsightsCalculator.topItemRankings(
            from: items,
            range: range,
            includeArchivedItems: includesArchivedItems
        )
        let quietRankings = ItemInsightsCalculator.quietItemRankings(
            from: items,
            range: range,
            includeArchivedItems: includesArchivedItems
        )

        return .init(
            range: range,
            includesArchivedItems: includesArchivedItems,
            activitySummary: activitySummary,
            activityDays: activityDays,
            streakSummary: streakSummary,
            cadenceSummary: cadenceSummary,
            healthSummary: healthSummary,
            categorySummaries: ItemInsightsCalculator.categorySummaries(
                from: items,
                range: range,
                includeArchivedItems: includesArchivedItems
            ),
            weekdaySummaries: ItemInsightsCalculator.weekdaySummaries(
                from: items,
                range: range,
                includeArchivedItems: includesArchivedItems
            ),
            monthlySummaries: ItemInsightsCalculator.monthlySummaries(
                from: items,
                range: range,
                includeArchivedItems: includesArchivedItems
            ),
            topRankings: topRankings,
            quietRankings: quietRankings,
            recommendations: ItemInsightsCalculator.recommendations(
                from: items,
                range: range,
                includeArchivedItems: includesArchivedItems
            ),
            itemsByID: itemsByID,
            reportText: StallyInsightsReportBuilder.build(
                range: range,
                includesArchivedItems: includesArchivedItems,
                activitySummary: activitySummary,
                streakSummary: streakSummary,
                healthSummary: healthSummary,
                topRankings: topRankings,
                quietRankings: quietRankings,
                itemsByID: itemsByID
            )
        )
    }
}
// swiftlint:enable file_types_order one_declaration_per_file function_body_length
