import MHUI
import StallyLibrary
import SwiftData
import SwiftUI

struct StallyArchiveView: View {
    @Environment(\.mhTheme)
    private var theme

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
                ForEach(items, id: \.id) { item in
                    archiveCard(item: item)
                }
            }
        }
        .mhScreen(
            title: Text("Archive"),
            subtitle: Text("Past favorites can stay nearby without crowding the main list.")
        )
    }
}

private extension StallyArchiveView {
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
