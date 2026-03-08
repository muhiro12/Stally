import MHUI
import StallyLibrary
import SwiftData
import SwiftUI

struct StallyInsightsView: View {
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass
    @Environment(\.mhTheme)
    private var theme

    @State private var selectedRange: ItemInsightsRange = .last30Days

    let items: [Item]

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.group) {
            overviewCard
            rangeSection
            activitySection
            cadenceSection
            categorySection
            rankingSection
            pendingSectionsCard
        }
        .mhScreen(
            title: Text("Insights"),
            subtitle: Text("Read the collection as a pattern, not just a list.")
        )
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension StallyInsightsView {
    var usesCompactLayout: Bool {
        horizontalSizeClass != .regular
    }

    var activitySummary: CollectionActivitySummary {
        ItemInsightsCalculator.activitySummary(
            from: items,
            range: selectedRange,
            includeArchivedItems: true
        )
    }

    var activityDays: [CollectionActivityDay] {
        ItemInsightsCalculator.activityDays(
            from: items,
            range: selectedRange,
            includeArchivedItems: true
        )
    }

    var streakSummary: CollectionStreakSummary {
        ItemInsightsCalculator.streakSummary(
            from: items,
            range: selectedRange,
            includeArchivedItems: true
        )
    }

    var cadenceSummary: CollectionCadenceSummary {
        ItemInsightsCalculator.cadenceSummary(
            from: items,
            range: selectedRange,
            includeArchivedItems: true
        )
    }

    var healthSummary: CollectionHealthSummary {
        ItemInsightsCalculator.healthSummary(
            from: items,
            range: selectedRange,
            includeArchivedItems: true
        )
    }

    var itemLookup: [UUID: Item] {
        Dictionary(
            uniqueKeysWithValues: items.map { item in
                (item.id, item)
            }
        )
    }

    var categorySummaries: [CollectionCategorySummary] {
        ItemInsightsCalculator.categorySummaries(
            from: items,
            range: selectedRange,
            includeArchivedItems: true
        )
    }

    var topRankings: [CollectionItemRanking] {
        ItemInsightsCalculator.topItemRankings(
            from: items,
            range: selectedRange,
            includeArchivedItems: true
        )
    }

    var quietRankings: [CollectionItemRanking] {
        ItemInsightsCalculator.quietItemRankings(
            from: items,
            range: selectedRange,
            includeArchivedItems: true
        )
    }

    var overviewMetrics: [StallyMetricGrid.Metric] {
        [
            .init(title: "Marks", value: "\(activitySummary.totalMarks)"),
            .init(title: "Active Days", value: "\(activitySummary.activeDays)"),
            .init(title: "Best Streak", value: "\(streakSummary.bestStreakDays)"),
            .init(title: "Items", value: "\(healthSummary.totalItems)")
        ]
    }

    var overviewCard: some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            HStack(alignment: .firstTextBaseline) {
                Text("Overview")
                    .mhRowTitle()

                Spacer(minLength: theme.spacing.control)

                Text(selectedRange.title)
                    .mhRowSupporting()
            }

            Text(
                """
                This foundation combines collection-wide activity, streaks, and health metrics.
                The next sections expand this into trends, rankings, and category views.
                """
            )
            .mhRowSupporting()

            StallyMetricGrid(
                metrics: overviewMetrics,
                usesCompactLayout: usesCompactLayout
            )
        }
        .mhSurfaceInset()
        .mhSurface(role: .muted)
    }

    var rangeSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            Text("Range")
                .mhRowTitle()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.control) {
                    ForEach(ItemInsightsRange.allCases, id: \.self) { range in
                        Button(range.title) {
                            selectedRange = range
                        }
                        .buttonStyle(
                            selectedRange == range
                                ? .mhPrimary
                                : .mhSecondary
                        )
                    }
                }
                .padding(.vertical, 2)
            }

            Text("All metrics on this screen follow the selected window.")
                .mhRowSupporting()
        }
        .mhSection(title: Text("Controls"))
    }

    var activitySection: some View {
        StallyInsightsActivitySection(
            days: activityDays,
            summary: activitySummary,
            usesCompactLayout: usesCompactLayout
        )
    }

    var cadenceSection: some View {
        StallyInsightsCadenceSection(
            streakSummary: streakSummary,
            cadenceSummary: cadenceSummary,
            usesCompactLayout: usesCompactLayout
        )
    }

    var categorySection: some View {
        StallyInsightsCategorySection(
            summaries: categorySummaries
        )
    }

    var rankingSection: some View {
        StallyInsightsRankingSection(
            itemsByID: itemLookup,
            topRankings: topRankings,
            quietRankings: quietRankings,
            usesCompactLayout: usesCompactLayout
        )
    }

    var pendingSectionsCard: some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            Text("More Sections Are Coming")
                .mhRowTitle()

            Text(
                """
                Category breakdowns, quiet-item rankings, monthly trends, and cadence views land here next.
                """
            )
            .mhRowSupporting()
        }
        .mhSurfaceInset()
        .mhSurface()
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(StallySampleData())) {
    @Previewable @Query var items: [Item]

    NavigationStack {
        StallyInsightsView(items: items)
    }
}
