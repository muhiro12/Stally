import MHPlatform
import MHUI
import StallyLibrary
import SwiftData
import SwiftUI
import UIKit

struct StallyArchiveView: View {
    @Environment(StallyAppModel.self)
    private var appModel
    @Environment(\.modelContext)
    private var context
    @Environment(\.stallyMHUIThemeMetrics)
    private var theme
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @Namespace private var quickFilterNamespace

    @State private var screenModel: StallyArchiveScreenModel

    let snapshot: StallyArchiveSnapshot
    let navigationNamespace: Namespace.ID

    var body: some View {
        if snapshot.archivedItems.isEmpty {
            screenContent
                .mhScreen(
                    title: Text("Archive"),
                    subtitle: Text("Past favorites can stay nearby without crowding the main list.")
                )
                .navigationTitle("Archive")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    toolbarContent
                }
                .task(id: snapshot.syncKey) {
                    screenModel.update(snapshot: snapshot)
                }
        } else {
            screenContent
                .mhScreen(
                    title: Text("Archive"),
                    subtitle: Text("Past favorites can stay nearby without crowding the main list.")
                )
                .navigationTitle("Archive")
                .navigationBarTitleDisplayMode(.inline)
                .searchable(
                    text: querySearchTextBinding,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Search archive"
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
        snapshot: StallyArchiveSnapshot,
        navigationNamespace: Namespace.ID
    ) {
        self.snapshot = snapshot
        self.navigationNamespace = navigationNamespace
        _screenModel = State(
            initialValue: .init(snapshot: snapshot)
        )
    }
}

private extension StallyArchiveView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Settings", systemImage: "gearshape") {
                appModel.openSettings(in: .archive)
            }
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
            if snapshot.archivedItems.isEmpty {
                emptyState
            } else {
                StallyItemQueryControls(
                    query: queryBinding,
                    displayedCount: screenModel.displayedItems.count,
                    usesCompactLayout: usesCompactLayout
                )
                archiveQuickFilters
                archiveSummaryCard

                if screenModel.displayedItems.isEmpty {
                    filteredEmptyState
                } else {
                    ForEach(screenModel.displayedItems, id: \.id) { item in
                        archiveCard(item: item)
                    }
                }
            }
        }
    }

    var usesCompactLayout: Bool {
        horizontalSizeClass != .regular
    }

    var archiveQuickFilters: some View {
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

    var archiveSummaryCard: some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            Text("Archive Snapshot")
                .mhRowTitle()

            Text(
                """
                Archived items keep their history,
                so this view stays focused on preserved use rather than active rotation.
                """
            )
            .mhRowSupporting()

            StallyMetricGrid(
                metrics: screenModel.archiveMetrics,
                usesCompactLayout: usesCompactLayout
            )
        }
        .mhSurfaceInset()
        .mhSurface(role: .muted)
    }

    var emptyState: some View {
        ContentUnavailableView(
            "No Archived Items",
            systemImage: "archivebox",
            description: Text("Archived items will wait here until you move them back into the Library.")
        )
        .mhEmptyStateLayout()
        .mhSurfaceInset()
        .mhSurface()
    }

    var filteredEmptyState: some View {
        ContentUnavailableView(
            "No Matching Archived Items",
            systemImage: "line.3.horizontal.decrease.circle",
            description: Text("Try a different search, category, or sort option.")
        )
        .mhEmptyStateLayout()
        .mhSurfaceInset()
        .mhSurface(role: .muted)
    }

    func itemLinkURL(
        for item: Item
    ) -> URL? {
        StallyDeepLinking.codec().preferredURL(
            for: .item(item.id)
        )
    }

    func archiveCard(
        item: Item
    ) -> some View {
        let summary = ItemInsightsCalculator.summary(for: item)

        return VStack(alignment: .leading, spacing: theme.spacing.control) {
            Button {
                appModel.openItem(
                    item.id,
                    in: .archive
                )
            } label: {
                archiveCardLabel(
                    item: item,
                    summary: summary
                )
            }
            .buttonStyle(.plain)
            .contextMenu {
                if let itemLinkURL = itemLinkURL(for: item) {
                    Button("Copy Item Link", systemImage: "link") {
                        UIPasteboard.general.url = itemLinkURL
                    }
                }
            }

            Button("Move Back to Library", systemImage: "tray.and.arrow.up.fill") {
                appModel.performAction {
                    try StallyAppActionService.unarchive(
                        context: context,
                        item: item
                    )
                }
            }
            .buttonStyle(.mhSecondary)
        }
    }

    func archiveCardLabel(
        item: Item,
        summary: ItemSummary
    ) -> some View {
        HStack(spacing: theme.spacing.group) {
            archiveArtwork(for: item)

            VStack(alignment: .leading, spacing: theme.spacing.control) {
                Text(item.name)
                    .mhRowTitle()

                Text(item.category.title)
                    .mhBadge(style: .neutral)

                Text(archiveDateText(for: item))
                    .mhRowSupporting()

                HStack(
                    alignment: .firstTextBaseline,
                    spacing: theme.spacing.control
                ) {
                    Text("Marks saved")
                        .mhRowSupporting()

                    Spacer(minLength: theme.spacing.control)

                    Text("\(summary.totalMarks)")
                        .mhRowValue(colorRole: .accent)
                }
            }

            Spacer(minLength: .zero)

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .mhSurfaceInset()
        .mhSurface()
    }

    @ViewBuilder
    func archiveArtwork(
        for item: Item
    ) -> some View {
        StallyItemArtworkView(
            photoData: item.photoData,
            category: item.category,
            width: 74,
            height: 88
        )
        .matchedTransitionSource(
            id: item.id,
            in: navigationNamespace
        )
    }

    func archiveDateText(
        for item: Item
    ) -> String {
        if let archivedAt = item.archivedAt {
            return StallyLocalization.format(
                "Archived %@",
                archivedAt.formatted(date: .abbreviated, time: .omitted)
            )
        }

        return StallyLocalization.string("Archived")
    }
}

@available(iOS 26.0, *)
#Preview(traits: .modifier(StallySampleData())) {
    @Previewable @Query var items: [Item]
    @Previewable @Namespace var namespace

    NavigationStack {
        StallyArchiveView(
            snapshot: StallyArchiveSnapshotBuilder.build(
                items: items
            ),
            navigationNamespace: namespace
        )
    }
}
