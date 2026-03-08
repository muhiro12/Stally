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
                ContentUnavailableView(
                    "No Archived Items",
                    systemImage: "archivebox",
                    description: Text("Archived items will wait here until you move them back into Home.")
                )
                .mhEmptyStateLayout()
                .mhSurfaceInset()
                .mhSurface()
            } else {
                queryControls
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

    var usesCompactLayout: Bool {
        horizontalSizeClass != .regular
    }

    var archiveSummaryMetrics: [(title: String, value: String)] {
        [
            ("Items", "\(displayedSummary.totalItems)"),
            ("With History", "\(displayedSummary.itemsWithMarksCount)"),
            ("Saved Marks", "\(displayedSummary.totalMarks)"),
            ("Latest Archive", latestArchiveTitle)
        ]
    }

    var summaryMetricGridColumns: [GridItem] {
        Array(
            repeating: GridItem(
                .flexible(minimum: 0, maximum: .infinity),
                spacing: theme.spacing.group,
                alignment: .leading
            ),
            count: 2
        )
    }

    var availableQuickFilters: [(title: String, filter: ItemListQuery.QuickFilter?)] {
        [
            ("All", nil),
            ("With History", .withHistory),
            ("Without History", .withoutHistory)
        ]
    }

    @ViewBuilder
    var queryControls: some View {
        if usesCompactLayout {
            VStack(alignment: .leading, spacing: theme.spacing.control) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: theme.spacing.control) {
                        categoryMenu
                        sortMenu

                        if query.hasRefinements {
                            clearFiltersButton
                        }
                    }
                    VStack(alignment: .leading, spacing: theme.spacing.control) {
                        categoryMenu
                        sortMenu

                        if query.hasRefinements {
                            clearFiltersButton
                        }
                    }
                }

                HStack(spacing: theme.spacing.control) {
                    queryStatusLabel
                    Spacer(minLength: .zero)
                }
            }
        } else {
            HStack(alignment: .center, spacing: theme.spacing.control) {
                categoryMenu
                sortMenu

                Spacer(minLength: theme.spacing.control)

                queryStatusLabel

                if query.hasRefinements {
                    clearFiltersButton
                }
            }
        }
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

    var archiveSummaryCard: some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            Text("Archive Snapshot")
                .mhRowTitle()

            Text("Archived items keep their history, so this view stays focused on preserved use rather than active rotation.")
                .mhRowSupporting()

            summaryMetricsSection(archiveSummaryMetrics)
        }
        .mhSurfaceInset()
        .mhSurface(role: .muted)
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

    var categoryControlTitle: String {
        query.category?.title ?? "All Categories"
    }

    var categoryMenu: some View {
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
                .lineLimit(1)
        }
        .buttonStyle(.mhSecondary)
        .fixedSize(horizontal: true, vertical: false)
    }

    var sortMenu: some View {
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
                .lineLimit(1)
        }
        .buttonStyle(.mhSecondary)
        .fixedSize(horizontal: true, vertical: false)
    }

    var queryStatusLabel: some View {
        Text("\(displayedItems.count) shown")
            .mhRowSupporting()
    }

    var clearFiltersButton: some View {
        Button("Clear") {
            query = .init()
        }
        .buttonStyle(.mhSecondary)
        .fixedSize(horizontal: true, vertical: false)
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

                if let archivedAt = item.archivedAt {
                    Text("Archived \(archivedAt.formatted(date: .abbreviated, time: .omitted))")
                        .mhRowSupporting()
                } else {
                    Text("Archived")
                        .mhRowSupporting()
                }

                HStack(alignment: .firstTextBaseline, spacing: theme.spacing.control) {
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

    @ViewBuilder
    func summaryMetricsSection(
        _ metrics: [(title: String, value: String)]
    ) -> some View {
        if usesCompactLayout {
            LazyVGrid(
                columns: summaryMetricGridColumns,
                alignment: .leading,
                spacing: theme.spacing.control
            ) {
                ForEach(metrics, id: \.title) { metric in
                    summaryMetric(
                        title: metric.title,
                        value: metric.value
                    )
                }
            }
        } else {
            HStack(spacing: theme.spacing.group) {
                ForEach(metrics, id: \.title) { metric in
                    summaryMetric(
                        title: metric.title,
                        value: metric.value
                    )
                }
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
                .fixedSize(horizontal: false, vertical: true)
            Text(value)
                .mhRowValue(colorRole: .accent)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(StallySampleData())) {
    @Previewable @Query var items: [Item]

    NavigationStack {
        StallyArchiveView(
            items: ItemInsightsCalculator.archivedItems(from: items),
            onOpenItem: { _ in
                // no-op
            }
        )
    }
}
