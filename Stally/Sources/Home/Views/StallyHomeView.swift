// swiftlint:disable closure_body_length file_length
import MHDeepLinking
import MHUI
import StallyLibrary
import SwiftData
import SwiftUI
import TipKit

struct StallyHomeView: View {
    private enum EmptyStateActionID: String, Sendable {
        case addFirstItem
        case trySampleItems
        case restoreFromBackup
    }

    @Environment(StallyAppModel.self)
    private var appModel
    @Environment(\.modelContext)
    private var context
    @Environment(\.stallyMHUIThemeMetrics)
    private var theme
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @Namespace private var quickFilterNamespace
    @Namespace private var emptyStateActionNamespace

    @State private var screenModel: StallyHomeScreenModel

    let snapshot: StallyLibrarySnapshot
    let navigationNamespace: Namespace.ID

    var body: some View {
        if snapshot.activeItems.isEmpty {
            screenContent
                .mhScreen(
                    title: Text(StallyAppConfiguration.displayName),
                    subtitle: Text("A quiet record of the things you keep choosing.")
                )
                .navigationTitle("Library")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    toolbarContent
                }
                .task(id: snapshot.syncKey) {
                    screenModel.update(snapshot: snapshot)
                }
        } else {
            screenContent
                .mhScreen(
                    title: Text(StallyAppConfiguration.displayName),
                    subtitle: Text("A quiet record of the things you keep choosing.")
                )
                .navigationTitle("Library")
                .navigationBarTitleDisplayMode(.large)
                .searchable(
                    text: querySearchTextBinding,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Search items"
                )
                .toolbar {
                    toolbarContent
                }
                .task(id: snapshot.syncKey) {
                    screenModel.update(snapshot: snapshot)
                }
        }
    }

    init(
        snapshot: StallyLibrarySnapshot,
        navigationNamespace: Namespace.ID
    ) {
        self.snapshot = snapshot
        self.navigationNamespace = navigationNamespace
        _screenModel = State(
            initialValue: .init(snapshot: snapshot)
        )
    }
}

private extension StallyHomeView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Settings", systemImage: "gearshape") {
                appModel.openSettings(in: .library)
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button("Add", systemImage: "plus") {
                appModel.presentCreateEditor()
            }
            .matchedTransitionSource(
                id: "create-item",
                in: navigationNamespace
            )
        }
    }

    var queryBinding: Binding<ItemListQuery> {
        .init(
            get: {
                screenModel.query
            },
            set: { newValue in
                screenModel.query = newValue
            }
        )
    }

    var querySearchTextBinding: Binding<String> {
        .init(
            get: {
                screenModel.query.searchText
            },
            set: { newValue in
                screenModel.query.searchText = newValue
            }
        )
    }

    var screenContent: some View {
        VStack(alignment: .leading, spacing: theme.spacing.group) {
            if snapshot.activeItems.isEmpty {
                emptyState
            } else {
                StallyItemQueryControls(
                    query: queryBinding,
                    displayedCount: screenModel.displayedItems.count,
                    usesCompactLayout: usesCompactLayout
                )
                homeQuickFilters
                homeSummaryCard
                reviewEntryCard
                insightsEntryCard
                archiveEntryCard
                backupEntryCard

                if screenModel.displayedItems.isEmpty {
                    filteredEmptyState
                } else {
                    ForEach(screenModel.displayedItems, id: \.id) { item in
                        StallyItemCard(
                            item: item,
                            summary: ItemInsightsCalculator.summary(for: item),
                            navigationNamespace: navigationNamespace,
                            onOpen: {
                                appModel.openItem(
                                    item.id,
                                    in: .library
                                )
                            },
                            onToggleTodayMark: {
                                appModel.performAction {
                                    try StallyAppActionService.toggleTodayMark(
                                        context: context,
                                        item: item
                                    )
                                }
                            }
                        )
                    }
                }
            }
        }
    }

    var usesCompactLayout: Bool {
        horizontalSizeClass != .regular
    }

    var reviewSummary: ItemReviewSummary {
        snapshot.reviewSummary
    }

    var archiveSummary: ItemInsightsCalculator.ArchiveCollectionSummary {
        snapshot.archiveSummary
    }

    var insightsActivitySummary: CollectionActivitySummary {
        snapshot.insightsActivitySummary
    }

    var insightsStreakSummary: CollectionStreakSummary {
        snapshot.insightsStreakSummary
    }

    var insightsHealthSummary: CollectionHealthSummary {
        snapshot.insightsHealthSummary
    }

    var totalLibraryItemCount: Int {
        snapshot.activeItems.count + archiveSummary.totalItems
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

        guard appModel.reviewPreferences.showCompletedSections else {
            return metrics.filter { $0.value != "0" }
        }

        return metrics
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
                value: "\(totalLibraryItemCount)"
            ),
            .init(
                title: StallyLocalization.string("Active"),
                value: "\(snapshot.activeItems.count)"
            ),
            .init(
                title: StallyLocalization.string("Archived"),
                value: "\(archiveSummary.totalItems)"
            ),
            .init(
                title: StallyLocalization.string("Marks"),
                value: "\(screenModel.displayedSummary.totalMarks + archiveSummary.totalMarks)"
            )
        ]
    }

    var homeQuickFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            StallyGlassContainer(spacing: theme.spacing.control) {
                HStack(spacing: theme.spacing.control) {
                    ForEach(screenModel.availableQuickFilters) { option in
                        Button(option.title) {
                            screenModel.selectQuickFilter(option.filter)
                        }
                        .buttonStyle(
                            option.filter == screenModel.query.quickFilter
                                ? .mhPrimary
                                : .mhSecondary
                        )
                        .stallyGlassEffectID(
                            option.id,
                            in: quickFilterNamespace
                        )
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    var homeSummaryCard: some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            Text("Collection Snapshot")
                .mhRowTitle()

            Text("The current Library view balances today's choices against what still has room to accumulate.")
                .mhRowSupporting()

            StallyMetricGrid(
                metrics: screenModel.homeSummaryMetrics,
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
            actionTip: openReviewTip,
            usesCompactLayout: usesCompactLayout
        ) {
            appModel.selectedTab = .review
        }
    }

    var archiveEntryCard: some View {
        StallyHomeEntryCard(
            title: StallyLocalization.string("Archive"),
            value: "\(archiveSummary.totalItems)",
            supporting: archiveCardSupportingText,
            metrics: archiveMetrics,
            primaryActionTitle: StallyLocalization.string("Open Archive"),
            routeURL: archiveRouteURL,
            usesCompactLayout: usesCompactLayout
        ) {
            appModel.selectedTab = .archive
        }
    }

    var insightsEntryCard: some View {
        StallyHomeEntryCard(
            title: StallyLocalization.string("Insights"),
            value: "\(insightsActivitySummary.totalMarks)",
            supporting: insightsCardSupportingText,
            metrics: insightsMetrics,
            primaryActionTitle: StallyLocalization.string("Open Insights"),
            routeURL: insightsRouteURL,
            usesCompactLayout: usesCompactLayout
        ) {
            appModel.selectedTab = .insights
        }
    }

    var backupEntryCard: some View {
        StallyHomeEntryCard(
            title: StallyLocalization.string("Backup Center"),
            value: "\(totalLibraryItemCount)",
            supporting: backupCardSupportingText,
            metrics: backupMetrics,
            primaryActionTitle: StallyLocalization.string("Open Backup Center"),
            routeURL: backupRouteURL,
            usesCompactLayout: usesCompactLayout
        ) {
            appModel.openBackup(in: .library)
        }
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

            StallyGlassContainer(spacing: theme.spacing.control) {
                VStack(alignment: .leading, spacing: theme.spacing.control) {
                    Button("Add Your First Item", systemImage: "plus.circle.fill") {
                        appModel.presentCreateEditor()
                    }
                    .buttonStyle(.mhPrimary)
                    .stallyGlassEffectID(
                        EmptyStateActionID.addFirstItem,
                        in: emptyStateActionNamespace
                    )
                    .popoverTip(addFirstItemTip, arrowEdge: .top)

                    Button("Try Sample Items", systemImage: "sparkles.rectangle.stack") {
                        appModel.performAction {
                            try StallyAppActionService.seedSampleData(
                                context: context
                            )
                        }
                    }
                    .buttonStyle(.mhSecondary)
                    .stallyGlassEffectID(
                        EmptyStateActionID.trySampleItems,
                        in: emptyStateActionNamespace
                    )

                    Button("Restore From Backup", systemImage: "externaldrive.badge.icloud") {
                        appModel.openBackup(in: .library)
                    }
                    .buttonStyle(.mhSecondary)
                    .stallyGlassEffectID(
                        EmptyStateActionID.restoreFromBackup,
                        in: emptyStateActionNamespace
                    )
                }
            }

            Text("Sample items only load when the library is empty, so you can safely try them once.")
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

    var archiveLatestDateTitle: String {
        archiveSummary.lastArchivedAt?.formatted(date: .abbreviated, time: .omitted)
            ?? StallyLocalization.string("None")
    }

    var reviewCardSupportingText: String {
        if reviewSummary.totalReviewCount == .zero,
           appModel.reviewPreferences.showCompletedSections == false {
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
                "Archived items will gather here once you clear space from the Library."
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
            "Read the last 30 days as a pattern: activity density, streaks, "
                + "and how much of the Library already has history."
        )
    }

    var backupCardSupportingText: String {
        if totalLibraryItemCount == .zero {
            return StallyLocalization.string(
                "Restore a previous snapshot or keep an export ready before you start tracking again."
            )
        }

        return StallyLocalization.string(
            "Export the full library, preview imported snapshots, and keep higher-risk restore actions in one place."
        )
    }

    var addFirstItemTip: (any Tip)? {
        if totalLibraryItemCount == .zero {
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

@available(iOS 26.0, *)
#Preview(traits: .modifier(StallySampleData())) {
    @Previewable @Query var items: [Item]
    @Previewable @Namespace var namespace

    NavigationStack {
        StallyHomeView(
            snapshot: StallyLibrarySnapshotBuilder.build(
                items: items,
                reviewPreferences: .init()
            ),
            navigationNamespace: namespace
        )
    }
}

@available(iOS 26.0, *)
#Preview("Empty Home", traits: .modifier(StallyEmptySampleData())) {
    @Previewable @Namespace var namespace

    NavigationStack {
        StallyHomeView(
            snapshot: StallyLibrarySnapshotBuilder.build(
                items: [],
                reviewPreferences: .init()
            ),
            navigationNamespace: namespace
        )
    }
}
// swiftlint:enable closure_body_length file_length
