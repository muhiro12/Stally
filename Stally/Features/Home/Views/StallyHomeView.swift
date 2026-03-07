import MHUI
import StallyLibrary
import SwiftData
import SwiftUI

struct StallyHomeView: View {
    @Environment(\.mhTheme)
    private var theme

    @State private var query = ItemListQuery()

    let items: [Item]
    let onOpenItem: (UUID) -> Void
    let onCreateItem: () -> Void
    let onOpenArchive: () -> Void
    let onToggleTodayMark: (Item) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.group) {
            if items.isEmpty {
                emptyState
            } else {
                queryControls

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
                Button("Add", systemImage: "plus") {
                    onCreateItem()
                }
            }
        }
    }
}

private extension StallyHomeView {
    var displayedItems: [Item] {
        ItemInsightsCalculator.items(
            from: items,
            matching: query,
            kind: .active
        )
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

    var categoryControlTitle: String {
        query.category?.title ?? "All Categories"
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
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(StallySampleData())) {
    @Previewable @Query var items: [Item]

    NavigationStack {
        StallyHomeView(
            items: ItemInsightsCalculator.homeSort(
                items: ItemInsightsCalculator.activeItems(from: items)
            ),
            onOpenItem: { _ in
                // no-op
            },
            onCreateItem: {
                // no-op
            },
            onOpenArchive: {
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
            onOpenItem: { _ in
                // no-op
            },
            onCreateItem: {
                // no-op
            },
            onOpenArchive: {
                // no-op
            },
            onToggleTodayMark: { _ in
                // no-op
            }
        )
    }
}
