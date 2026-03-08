import MHUI
import StallyLibrary
import SwiftData
import SwiftUI

struct StallyInsightsView: View {
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass
    @Environment(\.mhTheme)
    private var theme

    let items: [Item]
    @Binding var preferences: StallyInsightsPreferences

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.group) {
            overviewCard
            rangeSection
            activitySection
            cadenceSection
            categorySection
            rankingSection
            rhythmSection
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

    var selectedRange: ItemInsightsRange {
        preferences.defaultRange
    }

    var includeArchivedItems: Bool {
        preferences.includesArchivedItems
    }

    var activitySummary: CollectionActivitySummary {
        ItemInsightsCalculator.activitySummary(
            from: items,
            range: selectedRange,
            includeArchivedItems: includeArchivedItems
        )
    }

    var activityDays: [CollectionActivityDay] {
        ItemInsightsCalculator.activityDays(
            from: items,
            range: selectedRange,
            includeArchivedItems: includeArchivedItems
        )
    }

    var streakSummary: CollectionStreakSummary {
        ItemInsightsCalculator.streakSummary(
            from: items,
            range: selectedRange,
            includeArchivedItems: includeArchivedItems
        )
    }

    var cadenceSummary: CollectionCadenceSummary {
        ItemInsightsCalculator.cadenceSummary(
            from: items,
            range: selectedRange,
            includeArchivedItems: includeArchivedItems
        )
    }

    var healthSummary: CollectionHealthSummary {
        ItemInsightsCalculator.healthSummary(
            from: items,
            range: selectedRange,
            includeArchivedItems: includeArchivedItems
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
            includeArchivedItems: includeArchivedItems
        )
    }

    var weekdaySummaries: [CollectionWeekdaySummary] {
        ItemInsightsCalculator.weekdaySummaries(
            from: items,
            range: selectedRange,
            includeArchivedItems: includeArchivedItems
        )
    }

    var monthlySummaries: [CollectionMonthSummary] {
        ItemInsightsCalculator.monthlySummaries(
            from: items,
            range: selectedRange,
            includeArchivedItems: includeArchivedItems
        )
    }

    var topRankings: [CollectionItemRanking] {
        ItemInsightsCalculator.topItemRankings(
            from: items,
            range: selectedRange,
            includeArchivedItems: includeArchivedItems
        )
    }

    var quietRankings: [CollectionItemRanking] {
        ItemInsightsCalculator.quietItemRankings(
            from: items,
            range: selectedRange,
            includeArchivedItems: includeArchivedItems
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
                            preferences.defaultRange = range
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

            Toggle(
                "Include archived items",
                isOn: $preferences.includesArchivedItems
            )
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

    var rhythmSection: some View {
        StallyInsightsRhythmSection(
            weekdaySummaries: weekdaySummaries,
            monthlySummaries: monthlySummaries,
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
    @Previewable @State var preferences = StallyInsightsPreferences()

    NavigationStack {
        StallyInsightsView(
            items: items,
            preferences: $preferences
        )
    }
}
