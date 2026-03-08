import MHDeepLinking
import MHUI
import StallyLibrary
import SwiftData
import SwiftUI

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

    var body: some View {
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
        .mhScreen(
            title: Text(StallyAppConfiguration.displayName),
            subtitle: Text("A quiet record of the things you keep choosing.")
        )
        .searchable(
            text: $query.searchText,
            prompt: "Search items"
        )
        .toolbar {
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
    }
}

private extension StallyHomeView {
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

    var backupRouteURL: URL? {
        StallyDeepLinking.codec().preferredURL(for: .backup)
    }

    var homeSummaryMetrics: [StallyMetricGrid.Metric] {
        [
            .init(title: "Items", value: "\(displayedSummary.totalItems)"),
            .init(
                title: "Marked Today",
                value: "\(displayedSummary.markedTodayCount)"
            ),
            .init(
                title: "Untouched",
                value: "\(displayedSummary.neverMarkedCount)"
            ),
            .init(title: "Total Marks", value: "\(displayedSummary.totalMarks)")
        ]
    }

    var reviewMetrics: [StallyMetricGrid.Metric] {
        let metrics = [
            StallyMetricGrid.Metric(
                title: "First Mark",
                value: "\(reviewSummary.untouchedCount)"
            ),
            .init(title: "Dormant", value: "\(reviewSummary.dormantCount)"),
            .init(
                title: "Recovery",
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
            .init(title: "Items", value: "\(archiveSummary.totalItems)"),
            .init(
                title: "With History",
                value: "\(archiveSummary.itemsWithMarksCount)"
            ),
            .init(title: "Saved Marks", value: "\(archiveSummary.totalMarks)"),
            .init(title: "Latest Archive", value: archiveLatestDateTitle)
        ]
    }

    var backupMetrics: [StallyMetricGrid.Metric] {
        [
            .init(title: "Library", value: "\(items.count)"),
            .init(title: "Active", value: "\(displayedSummary.totalItems)"),
            .init(title: "Archived", value: "\(archiveSummary.totalItems)"),
            .init(
                title: "Marks",
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

            Text("The current Home view balances today’s choices against what still has room to accumulate.")
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
            title: "Needs Review",
            value: "\(reviewSummary.totalReviewCount)",
            supporting: reviewCardSupportingText,
            metrics: reviewMetrics,
            primaryActionTitle: "Open Review",
            routeURL: reviewRouteURL,
            usesCompactLayout: usesCompactLayout,
            onOpen: actions.onOpenReview
        )
    }

    var archiveEntryCard: some View {
        StallyHomeEntryCard(
            title: "Archive",
            value: "\(archiveSummary.totalItems)",
            supporting: archiveCardSupportingText,
            metrics: archiveMetrics,
            primaryActionTitle: "Open Archive",
            routeURL: archiveRouteURL,
            usesCompactLayout: usesCompactLayout,
            onOpen: actions.onOpenArchive
        )
    }

    var backupEntryCard: some View {
        StallyHomeEntryCard(
            title: "Backup Center",
            value: "\(items.count)",
            supporting: backupCardSupportingText,
            metrics: backupMetrics,
            primaryActionTitle: "Open Backup Center",
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
            ("All", nil),
            ("Open Today", .unmarkedOnReferenceDay),
            ("Marked Today", .markedOnReferenceDay),
            ("Never Marked", .withoutHistory)
        ]
    }

    var archiveLatestDateTitle: String {
        archiveSummary.lastArchivedAt?.formatted(date: .abbreviated, time: .omitted)
            ?? "None"
    }

    var reviewCardSupportingText: String {
        if reviewSummary.totalReviewCount == .zero,
           reviewPreferences.showCompletedSections == false {
            return """
                All review lanes are clear right now.
                Turn on completed sections in Settings to keep zero-count lanes visible.
                """
        }

        return "Surface items that need a first mark, feel dormant, or may deserve a return from Archive."
    }

    var archiveCardSupportingText: String {
        if archiveSummary.totalItems == .zero {
            return "Archived items will gather here once you clear space from Home."
        }

        return "Keep preserved favorites close without letting them crowd the active list."
    }

    var backupCardSupportingText: String {
        if items.isEmpty {
            return "Restore a previous snapshot or keep an export ready before you start tracking again."
        }

        return "Export the full library, preview imported snapshots, and keep higher-risk restore actions in one place."
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
