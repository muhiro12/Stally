import MHUI
import StallyLibrary
import SwiftData
import SwiftUI

struct StallyArchiveView: View {
    @Environment(\.mhTheme)
    private var theme

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

            HStack(spacing: theme.spacing.group) {
                summaryMetric(
                    title: "Items",
                    value: "\(displayedSummary.totalItems)"
                )
                summaryMetric(
                    title: "With History",
                    value: "\(displayedSummary.itemsWithMarksCount)"
                )
                summaryMetric(
                    title: "Saved Marks",
                    value: "\(displayedSummary.totalMarks)"
                )
                summaryMetric(
                    title: "Latest Archive",
                    value: latestArchiveTitle
                )
            }
        }
        .mhSurfaceInset()
        .mhSurface(role: .muted)
    }

    var categoryControlTitle: String {
        query.category?.title ?? "All Categories"
    }

    var latestArchiveTitle: String {
        displayedSummary.lastArchivedAt?.formatted(date: .abbreviated, time: .omitted)
            ?? "None"
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
        StallyArchiveView(
            items: ItemInsightsCalculator.archivedItems(from: items),
            onOpenItem: { _ in
                // no-op
            }
        )
    }
}
