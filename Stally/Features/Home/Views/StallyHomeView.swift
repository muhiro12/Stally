import MHUI
import StallyLibrary
import SwiftData
import SwiftUI

struct StallyHomeView: View {
    @Environment(\.mhTheme)
    private var theme

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
                ForEach(items, id: \.id) { item in
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
        .mhScreen(
            title: Text(StallyAppConfiguration.displayName),
            subtitle: Text("A quiet record of the things you keep choosing.")
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
