import StallyLibrary
import SwiftData
import SwiftUI

struct StallyHomeView: View {
    let items: [Item]
    let onOpenItem: (UUID) -> Void
    let onCreateItem: () -> Void
    let onOpenArchive: () -> Void
    let onToggleTodayMark: (Item) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                introSection

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
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .navigationTitle(StallyAppConfiguration.displayName)
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
        .stallyScreenBackground()
    }
}

private extension StallyHomeView {
    var introSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("A quiet record of the things you keep choosing.")
                .font(.system(size: 32, weight: .semibold, design: .serif))
                .foregroundStyle(.primary)

            Text("Add an item, mark it once when you chose it today, and let the accumulation build softly over time.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .stallyCardStyle(cornerRadius: 32)
    }

    var emptyState: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Start with a few pieces you actually reach for.")
                .font(.title3.weight(.semibold))

            Text("Clothing, shoes, bags, notebooks, or one small other category are enough to begin. Stally works best when it stays close to the objects you already choose by hand.")
                .font(.body)
                .foregroundStyle(.secondary)

            Button("Add Your First Item", systemImage: "plus.circle.fill") {
                onCreateItem()
            }
            .buttonStyle(.borderedProminent)
            .tint(StallyDesign.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .stallyCardStyle(cornerRadius: 32)
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
