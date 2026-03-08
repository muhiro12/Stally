import MHDeepLinking
import MHUI
import StallyLibrary
import SwiftData
import SwiftUI

struct StallyHomeView: View {
    @Environment(\.mhTheme)
    private var theme

    @State private var query = ItemListQuery()

    let items: [Item]
    let reviewPreferences: StallyReviewPreferences
    let reviewSummary: ItemReviewSummary
    let archiveSummary: ItemInsightsCalculator.ArchiveCollectionSummary
    let onOpenItem: (UUID) -> Void
    let onCreateItem: () -> Void
    let onSeedSampleData: () -> Void
    let onOpenArchive: () -> Void
    let onOpenBackup: () -> Void
    let onOpenReview: () -> Void
    let onOpenSettings: () -> Void
    let onToggleTodayMark: (Item) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.group) {
            if items.isEmpty {
                emptyState
            } else {
                queryControls
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
                                onOpenItem(item.id)
                            },
                            onToggleTodayMark: {
                                onToggleTodayMark(item)
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
                    onOpenArchive()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Settings", systemImage: "gearshape") {
                    onOpenSettings()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add", systemImage: "plus") {
                    onCreateItem()
                }
            }
        }
    }
}

private extension StallyHomeView {
    var reviewRouteURL: URL? {
        StallyDeepLinking.codec().preferredURL(
            for: .review
        )
    }

    var archiveRouteURL: URL? {
        StallyDeepLinking.codec().preferredURL(
            for: .archive
        )
    }

    var backupRouteURL: URL? {
        StallyDeepLinking.codec().preferredURL(
            for: .backup
        )
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

    var availableQuickFilters: [(title: String, filter: ItemListQuery.QuickFilter?)] {
        [
            ("All", nil),
            ("Open Today", .unmarkedOnReferenceDay),
            ("Marked Today", .markedOnReferenceDay),
            ("Never Marked", .withoutHistory)
        ]
    }

    var queryControls: some View {
        HStack(alignment: .center, spacing: theme.spacing.control) {
            Menu {
                Button("All Categories") {
                    query.category = nil
                }

                ForEach(ItemCategory.allCases, id: \.self) { category in
                    Button {
                        query.category = category
                    } label: {
                        categoryMenuLabel(for: category)
                    }
                }
            } label: {
                Label(categoryControlTitle, systemImage: "line.3.horizontal.decrease.circle")
            }
            .buttonStyle(.mhSecondary)

            Menu {
                ForEach(ItemListQuery.SortOption.allCases, id: \.self) { sortOption in
                    Button {
                        query.sortOption = sortOption
                    } label: {
                        sortMenuLabel(for: sortOption)
                    }
                }
            } label: {
                Label(query.sortOption.title, systemImage: "arrow.up.arrow.down.circle")
            }
            .buttonStyle(.mhSecondary)

            Spacer(minLength: theme.spacing.control)

            Text("\(displayedItems.count) shown")
                .mhRowSupporting()

            if query.hasRefinements {
                Button("Clear") {
                    query = .init()
                }
                .buttonStyle(.mhSecondary)
            }
        }
    }

    var emptyState: some View {
        VStack(alignment: .leading, spacing: theme.spacing.group) {
            ContentUnavailableView(
                "Start with a few pieces you actually reach for.",
                systemImage: "hanger",
                description: Text(
                    "Clothing, shoes, bags, notebooks, or one small other category are enough to begin. Add an item, mark it once when you chose it today, and let the accumulation build softly over time."
                )
            )
            .mhEmptyStateLayout()

            Button("Add Your First Item", systemImage: "plus.circle.fill") {
                onCreateItem()
            }
            .buttonStyle(.mhPrimary)

            Button("Try Sample Items", systemImage: "sparkles.rectangle.stack") {
                onSeedSampleData()
            }
            .buttonStyle(.mhSecondary)

            Button("Restore From Backup", systemImage: "externaldrive.badge.icloud") {
                onOpenBackup()
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

    var homeSummaryCard: some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            Text("Collection Snapshot")
                .mhRowTitle()

            Text("The current Home view balances today’s choices against what still has room to accumulate.")
                .mhRowSupporting()

            HStack(spacing: theme.spacing.group) {
                summaryMetric(
                    title: "Items",
                    value: "\(displayedSummary.totalItems)"
                )
                summaryMetric(
                    title: "Marked Today",
                    value: "\(displayedSummary.markedTodayCount)"
                )
                summaryMetric(
                    title: "Untouched",
                    value: "\(displayedSummary.neverMarkedCount)"
                )
                summaryMetric(
                    title: "Total Marks",
                    value: "\(displayedSummary.totalMarks)"
                )
            }
        }
        .mhSurfaceInset()
        .mhSurface(role: .muted)
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

    var reviewEntryCard: some View {
        routeEntryCard(
            title: "Needs Review",
            value: "\(reviewSummary.totalReviewCount)",
            supporting: reviewCardSupportingText,
            metrics: visibleReviewMetrics,
            primaryActionTitle: "Open Review",
            routeURL: reviewRouteURL,
            onOpen: onOpenReview
        )
    }

    var archiveEntryCard: some View {
        routeEntryCard(
            title: "Archive",
            value: "\(archiveSummary.totalItems)",
            supporting: archiveCardSupportingText,
            metrics: archiveEntryMetrics,
            primaryActionTitle: "Open Archive",
            routeURL: archiveRouteURL,
            onOpen: onOpenArchive
        )
    }

    var backupEntryCard: some View {
        routeEntryCard(
            title: "Backup Center",
            value: "\(items.count)",
            supporting: backupCardSupportingText,
            metrics: backupEntryMetrics,
            primaryActionTitle: "Open Backup Center",
            routeURL: backupRouteURL,
            onOpen: onOpenBackup
        )
    }

    var archiveEntryMetrics: [(title: String, value: String)] {
        [
            ("Items", "\(archiveSummary.totalItems)"),
            ("With History", "\(archiveSummary.itemsWithMarksCount)"),
            ("Saved Marks", "\(archiveSummary.totalMarks)"),
            ("Latest Archive", archiveLatestDateTitle)
        ]
    }

    var backupEntryMetrics: [(title: String, value: String)] {
        [
            ("Library", "\(items.count)"),
            ("Active", "\(displayedSummary.totalItems)"),
            ("Archived", "\(archiveSummary.totalItems)"),
            ("Marks", "\(displayedSummary.totalMarks + archiveSummary.totalMarks)")
        ]
    }

    var archiveLatestDateTitle: String {
        archiveSummary.lastArchivedAt?.formatted(date: .abbreviated, time: .omitted)
            ?? "None"
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

    func routeEntryCard(
        title: String,
        value: String,
        supporting: String,
        metrics: [(title: String, value: String)],
        primaryActionTitle: String,
        routeURL: URL?,
        onOpen: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .mhRowTitle()

                Spacer(minLength: theme.spacing.control)

                Text(value)
                    .mhRowValue(colorRole: .accent)
            }

            Text(supporting)
                .mhRowSupporting()

            if !metrics.isEmpty {
                HStack(spacing: theme.spacing.group) {
                    ForEach(metrics, id: \.title) { metric in
                        summaryMetric(
                            title: metric.title,
                            value: metric.value
                        )
                    }
                }
            }

            HStack(spacing: theme.spacing.control) {
                Button(primaryActionTitle) {
                    onOpen()
                }
                .buttonStyle(.mhSecondary)

                if let routeURL {
                    ShareLink(item: routeURL) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.mhSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .mhSurfaceInset()
        .mhSurface(role: .muted)
    }

    var categoryControlTitle: String {
        query.category?.title ?? "All Categories"
    }

    var visibleReviewMetrics: [(title: String, value: String)] {
        let metrics: [(title: String, value: String)] = [
            ("First Mark", "\(reviewSummary.untouchedCount)"),
            ("Dormant", "\(reviewSummary.dormantCount)"),
            ("Recovery", "\(reviewSummary.recoveryCandidateCount)")
        ]

        if reviewPreferences.showCompletedSections {
            return metrics
        }

        return metrics.filter { metric in
            metric.value != "0"
        }
    }

    var reviewCardSupportingText: String {
        if reviewSummary.totalReviewCount == .zero,
           reviewPreferences.showCompletedSections == false {
            return "All review lanes are clear right now. Turn on completed sections in Settings to keep zero-count lanes visible."
        }

        return "Surface items that need a first mark, feel dormant, or may deserve a return from Archive."
    }

    func categoryMenuLabel(
        for category: ItemCategory
    ) -> some View {
        Group {
            if query.category == category {
                Label(category.title, systemImage: "checkmark")
            } else {
                Text(category.title)
            }
        }
    }

    func sortMenuLabel(
        for sortOption: ItemListQuery.SortOption
    ) -> some View {
        Group {
            if query.sortOption == sortOption {
                Label(sortOption.title, systemImage: "checkmark")
            } else {
                Text(sortOption.title)
            }
        }
    }

    func summaryMetric(
        title: String,
        value: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .mhRowSupporting()
            Text(value)
                .mhRowValue(colorRole: .accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
            onOpenItem: { _ in
                // no-op
            },
            onCreateItem: {
                // no-op
            },
            onSeedSampleData: {
                // no-op
            },
            onOpenArchive: {
                // no-op
            },
            onOpenBackup: {
                // no-op
            },
            onOpenReview: {
                // no-op
            },
            onOpenSettings: {
                // no-op
            },
            onToggleTodayMark: { _ in
                // no-op
            }
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
            onOpenItem: { _ in
                // no-op
            },
            onCreateItem: {
                // no-op
            },
            onSeedSampleData: {
                // no-op
            },
            onOpenArchive: {
                // no-op
            },
            onOpenBackup: {
                // no-op
            },
            onOpenReview: {
                // no-op
            },
            onOpenSettings: {
                // no-op
            },
            onToggleTodayMark: { _ in
                // no-op
            }
        )
    }
}
