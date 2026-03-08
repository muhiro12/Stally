import MHDeepLinking
import MHUI
import StallyLibrary
import SwiftData
import SwiftUI
import UIKit

struct StallyArchiveView: View {
    @Environment(\.mhTheme)
    private var theme
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @State private var query = ItemListQuery()

    let items: [Item]
    let onOpenItem: (UUID) -> Void

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
                archiveQuickFilters
                archiveSummaryCard

                if displayedItems.isEmpty {
                    filteredEmptyState
                } else {
                    ForEach(displayedItems, id: \.id) { item in
                        archiveCard(item: item)
                    }
                }
            }
        }
        .mhScreen(
            title: Text("Archive"),
            subtitle: Text("Past favorites can stay nearby without crowding the main list.")
        )
        .searchable(
            text: $query.searchText,
            prompt: "Search archive"
        )
    }
}

private extension StallyArchiveView {
    var usesCompactLayout: Bool {
        horizontalSizeClass != .regular
    }

    var displayedItems: [Item] {
        ItemInsightsCalculator.items(
            from: items,
            matching: query,
            kind: .archived
        )
    }

    var displayedSummary: ItemInsightsCalculator.ArchiveCollectionSummary {
        ItemInsightsCalculator.archiveSummary(from: displayedItems)
    }

    var archiveSummaryMetrics: [StallyMetricGrid.Metric] {
        [
            .init(title: "Items", value: "\(displayedSummary.totalItems)"),
            .init(
                title: "With History",
                value: "\(displayedSummary.itemsWithMarksCount)"
            ),
            .init(title: "Saved Marks", value: "\(displayedSummary.totalMarks)"),
            .init(title: "Latest Archive", value: latestArchiveTitle)
        ]
    }

    var archiveQuickFilters: some View {
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
                metrics: archiveSummaryMetrics,
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
            description: Text("Archived items will wait here until you move them back into Home.")
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

    var availableQuickFilters: [(title: String, filter: ItemListQuery.QuickFilter?)] {
        [
            ("All", nil),
            ("With History", .withHistory),
            ("Without History", .withoutHistory)
        ]
    }

    var latestArchiveTitle: String {
        displayedSummary.lastArchivedAt?.formatted(date: .abbreviated, time: .omitted)
            ?? "None"
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

        return Button {
            onOpenItem(item.id)
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
    }

    func archiveCardLabel(
        item: Item,
        summary: ItemSummary
    ) -> some View {
        HStack(spacing: theme.spacing.group) {
            StallyItemArtworkView(
                photoData: item.photoData,
                category: item.category,
                width: 74,
                height: 88
            )

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

    func archiveDateText(
        for item: Item
    ) -> String {
        if let archivedAt = item.archivedAt {
            return "Archived \(archivedAt.formatted(date: .abbreviated, time: .omitted))"
        }

        return "Archived"
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(StallySampleData())) {
    @Previewable @Query var items: [Item]

    NavigationStack {
        StallyArchiveView(
            items: ItemInsightsCalculator.archivedItems(from: items)
        ) { _ in
            // no-op
        }
    }
}
