import MHDeepLinking
import MHUI
import StallyLibrary
import SwiftData
import SwiftUI
import TipKit

// swiftlint:disable file_length
struct StallyHomeView: View {
    @Environment(\.mhTheme)
    private var theme
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @State private var query = ItemListQuery()

    let items: [Item]
    let reviewPreferences: StallyReviewPreferences
    let reviewSummary: ItemReviewSummary
    let archiveSummary: ItemInsightsCalculator.ArchiveCollectionSummary
    let actions: StallyHomeActions

    @ViewBuilder
    var body: some View {
        if items.isEmpty {
            screenContent
                .mhScreen(
                    title: Text(StallyAppConfiguration.displayName),
                    subtitle: Text("A quiet record of the things you keep choosing.")
                )
                .toolbar {
                    homeToolbar
                }
        } else {
            screenContent
                .mhScreen(
                    title: Text(StallyAppConfiguration.displayName),
                    subtitle: Text("A quiet record of the things you keep choosing.")
                )
                .searchable(
                    text: $query.searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Search items"
                )
                .toolbar {
                    homeToolbar
                }
        }
    }
}
private extension StallyHomeView {
    // swiftlint:disable closure_body_length
    var screenContent: some View {
        VStack(alignment: .leading, spacing: theme.spacing.group) {
            if items.isEmpty {
                emptyState
            } else {
                StallyItemQueryControls(
                    query: $query,
                    displayedCount: displayedItems.count,
                    usesCompactLayout: usesCompactLayout
                )
                homeQuickFilters
                homeSummaryCard
                reviewEntryCard
                insightsEntryCard
                archiveEntryCard
                backupEntryCard

                if displayedItems.isEmpty {
                    filteredEmptyState
                } else {
                    ForEach(displayedItems, id: \.id) { item in
                        StallyItemCard(
                            item: item,
                            summary: ItemInsightsCalculator.summary(for: item),
                            onOpen: {
                                actions.onOpenItem(item.id)
                            },
                            onToggleTodayMark: {
                                actions.onToggleTodayMark(item)
                            }
                        )
                    }
                }
            }
        }
    }
    // swiftlint:enable closure_body_length

    @ToolbarContentBuilder
    var homeToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Archive", systemImage: "archivebox") {
                actions.onOpenArchive()
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button("Settings", systemImage: "gearshape") {
                actions.onOpenSettings()
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button("Add", systemImage: "plus") {
                actions.onCreateItem()
            }
        }
    }

    var usesCompactLayout: Bool {
        horizontalSizeClass != .regular
    }

    var displayedItems: [Item] {
        ItemInsightsCalculator.items(
            from: items,
            matching: query,
            kind: .active
        )
    }

    var displayedSummary: ItemInsightsCalculator.ActiveCollectionSummary {
        ItemInsightsCalculator.activeSummary(from: displayedItems)
    }

    var reviewRouteURL: URL? {
        StallyDeepLinking.codec().preferredURL(for: .review)
    }

    var archiveRouteURL: URL? {
        StallyDeepLinking.codec().preferredURL(for: .archive)
    }

    var insightsRouteURL: URL? {
        StallyDeepLinking.codec().preferredURL(for: .insights)
    }

    var backupRouteURL: URL? {
        StallyDeepLinking.codec().preferredURL(for: .backup)
    }

    var insightsActivitySummary: CollectionActivitySummary {
        ItemInsightsCalculator.activitySummary(
            from: items,
            range: .last30Days
        )
    }

    var insightsStreakSummary: CollectionStreakSummary {
        ItemInsightsCalculator.streakSummary(
            from: items,
            range: .last30Days
        )
    }

    var insightsHealthSummary: CollectionHealthSummary {
        ItemInsightsCalculator.healthSummary(
            from: items,
            range: .last30Days,
            includeArchivedItems: false
        )
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
            )
        ]
    }

    var reviewMetrics: [StallyMetricGrid.Metric] {
        let metrics = [
            StallyMetricGrid.Metric(
                title: StallyLocalization.string("First Mark"),
                value: "\(reviewSummary.untouchedCount)"
            ),
            .init(
                title: StallyLocalization.string("Dormant"),
                value: "\(reviewSummary.dormantCount)"
            ),
            .init(
                title: StallyLocalization.string("Recovery"),
                value: "\(reviewSummary.recoveryCandidateCount)"
            )
        ]

        guard !reviewPreferences.showCompletedSections else {
            return metrics
        }

        return metrics.filter { $0.value != "0" }
    }

    var archiveMetrics: [StallyMetricGrid.Metric] {
        [
            .init(
                title: StallyLocalization.string("Items"),
                value: "\(archiveSummary.totalItems)"
            ),
            .init(
                title: StallyLocalization.string("With History"),
                value: "\(archiveSummary.itemsWithMarksCount)"
            ),
            .init(
                title: StallyLocalization.string("Saved Marks"),
                value: "\(archiveSummary.totalMarks)"
            ),
            .init(
                title: StallyLocalization.string("Latest Archive"),
                value: archiveLatestDateTitle
            )
        ]
    }

    var insightsMetrics: [StallyMetricGrid.Metric] {
        [
            .init(
                title: StallyLocalization.string("Marks (30d)"),
                value: "\(insightsActivitySummary.totalMarks)"
            ),
            .init(
                title: StallyLocalization.string("Active Days"),
                value: "\(insightsActivitySummary.activeDays)"
            ),
            .init(
                title: StallyLocalization.string("Current Streak"),
                value: "\(insightsStreakSummary.currentStreakDays)"
            ),
            .init(
                title: StallyLocalization.string("With History"),
                value: "\(insightsHealthSummary.itemsWithHistory)"
            )
        ]
    }

    var backupMetrics: [StallyMetricGrid.Metric] {
        [
            .init(
                title: StallyLocalization.string("Library"),
                value: "\(items.count)"
            ),
            .init(
                title: StallyLocalization.string("Active"),
                value: "\(displayedSummary.totalItems)"
            ),
            .init(
                title: StallyLocalization.string("Archived"),
                value: "\(archiveSummary.totalItems)"
            ),
            .init(
                title: StallyLocalization.string("Marks"),
                value: "\(displayedSummary.totalMarks + archiveSummary.totalMarks)"
            )
        ]
    }

    var homeQuickFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme.spacing.control) {
                ForEach(availableQuickFilters, id: \.title) { option in
                    Button(option.title) {
                        query.quickFilter = option.filter
                    }
                    .buttonStyle(
                        option.filter == query.quickFilter
                            ? .mhPrimary
                            : .mhSecondary
                    )
                }
            }
            .padding(.vertical, 2)
        }
    }

    var homeSummaryCard: some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            Text("Collection Snapshot")
                .mhRowTitle()

            Text("The current Home view balances today's choices against what still has room to accumulate.")
                .mhRowSupporting()

            StallyMetricGrid(
                metrics: homeSummaryMetrics,
                usesCompactLayout: usesCompactLayout
            )
        }
        .mhSurfaceInset()
        .mhSurface(role: .muted)
    }

    var reviewEntryCard: some View {
        StallyHomeEntryCard(
            title: StallyLocalization.string("Needs Review"),
            value: "\(reviewSummary.totalReviewCount)",
            supporting: reviewCardSupportingText,
            metrics: reviewMetrics,
            primaryActionTitle: StallyLocalization.string("Open Review"),
            routeURL: reviewRouteURL,
            primaryActionTip: openReviewTip,
            usesCompactLayout: usesCompactLayout,
            onOpen: actions.onOpenReview
        )
    }

    var archiveEntryCard: some View {
        StallyHomeEntryCard(
            title: StallyLocalization.string("Archive"),
            value: "\(archiveSummary.totalItems)",
            supporting: archiveCardSupportingText,
            metrics: archiveMetrics,
            primaryActionTitle: StallyLocalization.string("Open Archive"),
            routeURL: archiveRouteURL,
            usesCompactLayout: usesCompactLayout,
            onOpen: actions.onOpenArchive
        )
    }

    var insightsEntryCard: some View {
        StallyHomeEntryCard(
            title: StallyLocalization.string("Insights"),
            value: "\(insightsActivitySummary.totalMarks)",
            supporting: insightsCardSupportingText,
            metrics: insightsMetrics,
            primaryActionTitle: StallyLocalization.string("Open Insights"),
            routeURL: insightsRouteURL,
            usesCompactLayout: usesCompactLayout,
            onOpen: actions.onOpenInsights
        )
    }

    var backupEntryCard: some View {
        StallyHomeEntryCard(
            title: StallyLocalization.string("Backup Center"),
            value: "\(items.count)",
            supporting: backupCardSupportingText,
            metrics: backupMetrics,
            primaryActionTitle: StallyLocalization.string("Open Backup Center"),
            routeURL: backupRouteURL,
            usesCompactLayout: usesCompactLayout,
            onOpen: actions.onOpenBackup
        )
    }

    var emptyState: some View {
        VStack(alignment: .leading, spacing: theme.spacing.group) {
            ContentUnavailableView(
                "Start with a few pieces you actually reach for.",
                systemImage: "hanger",
                description: Text(
                    """
                    Clothing, shoes, bags, notebooks, or one small other category are enough to begin.
                    Add an item, mark it once when you chose it today, and let the accumulation build softly over time.
                    """
                )
            )
            .mhEmptyStateLayout()

            Button("Add Your First Item", systemImage: "plus.circle.fill") {
                actions.onCreateItem()
            }
            .buttonStyle(.mhPrimary)
            .popoverTip(addFirstItemTip, arrowEdge: .top)

            Button("Try Sample Items", systemImage: "sparkles.rectangle.stack") {
                actions.onSeedSampleData()
            }
            .buttonStyle(.mhSecondary)

            Button("Restore From Backup", systemImage: "externaldrive.badge.icloud") {
                actions.onOpenBackup()
            }
            .buttonStyle(.mhSecondary)

            Text("Sample items only load when Home is empty, so you can safely try them once.")
                .mhRowSupporting()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .mhSurfaceInset()
        .mhSurface()
    }

    var filteredEmptyState: some View {
        ContentUnavailableView(
            "No Matching Items",
            systemImage: "line.3.horizontal.decrease.circle",
            description: Text("Try a different search, category, or sort option.")
        )
        .mhEmptyStateLayout()
        .mhSurfaceInset()
        .mhSurface(role: .muted)
    }

    var availableQuickFilters: [(title: String, filter: ItemListQuery.QuickFilter?)] {
        [
            (StallyLocalization.string("All"), nil),
            (StallyLocalization.string("Open Today"), .unmarkedOnReferenceDay),
            (StallyLocalization.string("Marked Today"), .markedOnReferenceDay),
            (StallyLocalization.string("Never Marked"), .withoutHistory)
        ]
    }

    var archiveLatestDateTitle: String {
        archiveSummary.lastArchivedAt?.formatted(date: .abbreviated, time: .omitted)
            ?? StallyLocalization.string("None")
    }

    var reviewCardSupportingText: String {
        if reviewSummary.totalReviewCount == .zero,
           reviewPreferences.showCompletedSections == false {
            return StallyLocalization.string(
                """
                All review lanes are clear right now.
                Turn on completed sections in Settings to keep zero-count lanes visible.
                """
            )
        }

        return StallyLocalization.string(
            "Surface items that need a first mark, feel dormant, or may deserve a return from Archive."
        )
    }

    var archiveCardSupportingText: String {
        if archiveSummary.totalItems == .zero {
            return StallyLocalization.string(
                "Archived items will gather here once you clear space from Home."
            )
        }

        return StallyLocalization.string(
            "Keep preserved favorites close without letting them crowd the active list."
        )
    }

    var insightsCardSupportingText: String {
        if insightsActivitySummary.totalMarks == .zero {
            return StallyLocalization.string(
                "Once marks start to accumulate, Insights will map cadence, trends, and coverage across the collection."
            )
        }

        return StallyLocalization.string(
            "Read the last 30 days as a pattern: activity density, streaks, and how much of Home already has history."
        )
    }

    var backupCardSupportingText: String {
        if items.isEmpty {
            return StallyLocalization.string(
                "Restore a previous snapshot or keep an export ready before you start tracking again."
            )
        }

        return StallyLocalization.string(
            "Export the full library, preview imported snapshots, and keep higher-risk restore actions in one place."
        )
    }

    var addFirstItemTip: (any Tip)? {
        if items.isEmpty {
            return StallyTips.AddFirstItemTip()
        }

        return nil
    }

    var openReviewTip: (any Tip)? {
        if reviewSummary.totalReviewCount > .zero {
            return StallyTips.OpenReviewTip()
        }

        return nil
    }
}
@available(iOS 18.0, *)
#Preview(traits: .modifier(StallySampleData())) {
    @Previewable @Query var items: [Item]

    NavigationStack {
        StallyHomeView(
            items: ItemInsightsCalculator.homeSort(
                items: ItemInsightsCalculator.activeItems(from: items)
            ),
            reviewPreferences: .init(),
            reviewSummary: ItemReviewCalculator.summary(from: items),
            archiveSummary: ItemInsightsCalculator.archiveSummary(
                from: ItemInsightsCalculator.archivedItems(from: items)
            ),
            actions: .noop
        )
    }
}

@available(iOS 18.0, *)
#Preview("Empty Home", traits: .modifier(StallyEmptySampleData())) {
    NavigationStack {
        StallyHomeView(
            items: [],
            reviewPreferences: .init(),
            reviewSummary: ItemReviewCalculator.summary(from: []),
            archiveSummary: ItemInsightsCalculator.archiveSummary(from: []),
            actions: .noop
        )
    }
}
// swiftlint:enable file_length
