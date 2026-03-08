import MHUI
import StallyLibrary
import SwiftData
import SwiftUI

struct StallyReviewView: View {
    @Environment(\.mhTheme)
    private var theme

    let items: [Item]
    let policy: ItemReviewPolicy
    let onArchiveItem: (Item) -> Void
    let onOpenItem: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.group) {
            summaryCard

            if summary.totalReviewCount == .zero {
                emptyState
            } else {
                if !untouchedItems.isEmpty {
                    reviewSection(
                        title: "Needs First Mark",
                        supporting: "Items that have been waiting quietly without a first mark.",
                        items: untouchedItems,
                        actionTitle: "Archive Item",
                        onItemAction: onArchiveItem
                    )
                }

                if !dormantItems.isEmpty {
                    reviewSection(
                        title: "Dormant",
                        supporting: "Items whose last mark feels far enough away to revisit.",
                        items: dormantItems
                    )
                }

                if !recoveryCandidateItems.isEmpty {
                    reviewSection(
                        title: "Recovery Candidates",
                        supporting: "Archived items with enough history that they may deserve another turn.",
                        items: recoveryCandidateItems
                    )
                }
            }
        }
        .mhScreen(
            title: Text("Review"),
            subtitle: Text("Find the items that deserve attention before they drift too far out of mind.")
        )
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension StallyReviewView {
    var summary: ItemReviewSummary {
        ItemReviewCalculator.summary(
            from: items,
            policy: policy
        )
    }

    var activeItems: [Item] {
        ItemInsightsCalculator.homeSort(
            items: ItemInsightsCalculator.activeItems(from: items)
        )
    }

    var archivedItems: [Item] {
        ItemInsightsCalculator.archivedItems(from: items)
    }

    var untouchedItems: [Item] {
        ItemReviewCalculator.items(
            from: activeItems,
            with: .untouched,
            policy: policy
        )
    }

    var dormantItems: [Item] {
        ItemReviewCalculator.items(
            from: activeItems,
            with: .dormant,
            policy: policy
        )
    }

    var recoveryCandidateItems: [Item] {
        ItemReviewCalculator.items(
            from: archivedItems,
            with: .recoveryCandidate,
            policy: policy
        )
    }

    var snapshotsByID: [UUID: ItemReviewSnapshot] {
        Dictionary(
            uniqueKeysWithValues: ItemReviewCalculator.snapshots(
                from: items,
                policy: policy
            ).map { snapshot in
                (snapshot.itemID, snapshot)
            }
        )
    }

    var summaryCard: some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            HStack(alignment: .firstTextBaseline) {
                Text("Review Snapshot")
                    .mhRowTitle()

                Spacer(minLength: theme.spacing.control)

                Text("\(summary.totalReviewCount)")
                    .mhRowValue(colorRole: .accent)
            }

            Text("This brings together first-use lag, inactivity, and archive recovery into one review lane.")
                .mhRowSupporting()

            HStack(spacing: theme.spacing.group) {
                summaryMetric(
                    title: "First Mark",
                    value: "\(summary.untouchedCount)"
                )
                summaryMetric(
                    title: "Dormant",
                    value: "\(summary.dormantCount)"
                )
                summaryMetric(
                    title: "Recovery",
                    value: "\(summary.recoveryCandidateCount)"
                )
            }
        }
        .mhSurfaceInset()
        .mhSurface(role: .muted)
    }

    var emptyState: some View {
        ContentUnavailableView(
            "Nothing Needs Review",
            systemImage: "checkmark.circle",
            description: Text("Items that need a first mark, feel dormant, or look ready to return from Archive will appear here.")
        )
        .mhEmptyStateLayout()
        .mhSurfaceInset()
        .mhSurface()
    }

    func reviewSection(
        title: String,
        supporting: String,
        items: [Item],
        actionTitle: String? = nil,
        onItemAction: ((Item) -> Void)? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            ForEach(items, id: \.id) { item in
                if let actionTitle,
                   let onItemAction {
                    actionableReviewRow(
                        item: item,
                        actionTitle: actionTitle,
                        onItemAction: onItemAction
                    )
                } else {
                    reviewRow(item: item)
                }
            }
        }
        .mhSection(
            title: Text(title),
            supporting: Text(supporting)
        )
    }

    func actionableReviewRow(
        item: Item,
        actionTitle: String,
        onItemAction: @escaping (Item) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            reviewRow(item: item)

            Button(actionTitle) {
                onItemAction(item)
            }
            .buttonStyle(.mhSecondary)
        }
    }

    func reviewRow(
        item: Item
    ) -> some View {
        let summary = ItemInsightsCalculator.summary(for: item)
        let snapshot = snapshotsByID[item.id]

        return Button {
            onOpenItem(item.id)
        } label: {
            HStack(spacing: theme.spacing.group) {
                StallyItemArtworkView(
                    photoData: item.photoData,
                    category: item.category,
                    width: 68,
                    height: 82
                )

                VStack(alignment: .leading, spacing: theme.spacing.control) {
                    Text(item.name)
                        .mhRowTitle()

                    Text(item.category.title)
                        .mhBadge(style: .neutral)

                    Text(rowSupportingText(summary: summary, snapshot: snapshot))
                        .mhRowSupporting()
                }

                Spacer(minLength: .zero)

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .mhSurfaceInset()
            .mhSurface()
        }
        .buttonStyle(.plain)
    }

    func rowSupportingText(
        summary: ItemSummary,
        snapshot: ItemReviewSnapshot?
    ) -> String {
        if let daysSinceLastMark = snapshot?.daysSinceLastMark {
            return "\(summary.totalMarks) marks • last used \(daysSinceLastMark)d ago"
        }

        if let daysSinceCreated = snapshot?.daysSinceCreated {
            return "\(summary.totalMarks) marks • added \(daysSinceCreated)d ago"
        }

        return "\(summary.totalMarks) marks"
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
        StallyReviewView(
            items: items,
            policy: .init(),
            onArchiveItem: { _ in
                // no-op
            },
            onOpenItem: { _ in
                // no-op
            }
        )
    }
}
