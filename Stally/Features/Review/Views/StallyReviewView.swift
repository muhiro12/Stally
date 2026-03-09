import MHDeepLinking
import MHUI
import StallyLibrary
import SwiftData
import SwiftUI

struct StallyReviewView: View {
    enum SelectionTipLane {
        case untouched
        case dormant
        case recovery
    }

    @Environment(\.mhTheme)
    private var theme
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @State private var selectionState = StallyReviewSelectionState()

    let items: [Item]
    let preferences: StallyReviewPreferences
    let onArchiveItem: (Item) -> Void
    let onArchiveItems: ([Item]) -> Void
    let onUnarchiveItem: (Item) -> Void
    let onUnarchiveItems: ([Item]) -> Void
    let onOpenItem: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.group) {
            summaryCard

            if summary.totalReviewCount == .zero, !showsCompletedSections {
                emptyState
            } else {
                if shouldShowUntouchedSection {
                    untouchedSection
                }

                if shouldShowDormantSection {
                    dormantSection
                }

                if shouldShowRecoverySection {
                    recoverySection
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
    var usesCompactLayout: Bool {
        horizontalSizeClass != .regular
    }

    var policy: ItemReviewPolicy {
        preferences.policy
    }

    var showsCompletedSections: Bool {
        preferences.showCompletedSections
    }

    var summary: ItemReviewSummary {
        ItemReviewCalculator.summary(
            from: items,
            policy: policy
        )
    }

    var summaryMetrics: [StallyMetricGrid.Metric] {
        [
            .init(
                title: StallyLocalization.string("First Mark"),
                value: "\(summary.untouchedCount)"
            ),
            .init(
                title: StallyLocalization.string("Dormant"),
                value: "\(summary.dormantCount)"
            ),
            .init(
                title: StallyLocalization.string("Recovery"),
                value: "\(summary.recoveryCandidateCount)"
            )
        ]
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
            uniqueKeysWithValues: ItemReviewCalculator
                .snapshots(
                    from: items,
                    policy: policy
                )
                .map { snapshot in
                    (snapshot.itemID, snapshot)
                }
        )
    }

    var shouldShowUntouchedSection: Bool {
        showsCompletedSections || !untouchedItems.isEmpty
    }

    var shouldShowDormantSection: Bool {
        showsCompletedSections || !dormantItems.isEmpty
    }

    var shouldShowRecoverySection: Bool {
        showsCompletedSections || !recoveryCandidateItems.isEmpty
    }

    var selectionTipLane: SelectionTipLane? {
        if shouldShowUntouchedSection, untouchedItems.count >= 2 {
            return .untouched
        }

        if shouldShowDormantSection, dormantItems.count >= 2 {
            return .dormant
        }

        if shouldShowRecoverySection, recoveryCandidateItems.count >= 2 {
            return .recovery
        }

        return nil
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

            StallyMetricGrid(
                metrics: summaryMetrics,
                usesCompactLayout: usesCompactLayout
            )
        }
        .mhSurfaceInset()
        .mhSurface(role: .muted)
    }

    var emptyState: some View {
        ContentUnavailableView(
            "Nothing Needs Review",
            systemImage: "checkmark.circle",
            description: Text(
                "Items that need a first mark, feel dormant, or look ready to return from Archive will appear here."
            )
        )
        .mhEmptyStateLayout()
        .mhSurfaceInset()
        .mhSurface()
    }

    var untouchedSection: some View {
        StallyReviewLaneSection(
            selection: $selectionState.untouched,
            configuration: .init(
                title: StallyLocalization.string("Needs First Mark"),
                supporting: StallyLocalization.string(
                    "Items that have been waiting quietly without a first mark."
                ),
                emptyMessage: StallyLocalization.string("Nothing in this lane right now."),
                itemActionTitle: StallyLocalization.string("Archive Item"),
                bulkActionTitle: StallyLocalization.string("Archive Selected"),
                confirmationTitle: StallyLocalization.string("Archive Selected Items"),
                confirmationMessage: { count in
                    StallyLocalization.format(
                        "Archive %lld items that still have no marks?",
                        count
                    )
                },
                confirmationButtonTitle: StallyLocalization.string("Archive Selected"),
                confirmationButtonRole: .destructive
            ),
            items: untouchedItems,
            snapshotsByID: snapshotsByID,
            onOpenItem: onOpenItem,
            onItemAction: onArchiveItem,
            onBulkAction: onArchiveItems,
            itemLinkURL: itemLinkURL(for:),
            showsSelectionTip: selectionTipLane == .untouched
        )
    }

    var dormantSection: some View {
        StallyReviewLaneSection(
            selection: $selectionState.dormant,
            configuration: .init(
                title: StallyLocalization.string("Dormant"),
                supporting: StallyLocalization.string(
                    "Items whose last mark feels far enough away to revisit."
                ),
                emptyMessage: StallyLocalization.string("Nothing currently looks dormant."),
                itemActionTitle: StallyLocalization.string("Archive Item"),
                bulkActionTitle: StallyLocalization.string("Archive Selected"),
                confirmationTitle: StallyLocalization.string("Archive Selected Items"),
                confirmationMessage: { count in
                    StallyLocalization.format(
                        "Archive %lld dormant items and move them into Recovery Candidates?",
                        count
                    )
                },
                confirmationButtonTitle: StallyLocalization.string("Archive Selected"),
                confirmationButtonRole: .destructive
            ),
            items: dormantItems,
            snapshotsByID: snapshotsByID,
            onOpenItem: onOpenItem,
            onItemAction: onArchiveItem,
            onBulkAction: onArchiveItems,
            itemLinkURL: itemLinkURL(for:),
            showsSelectionTip: selectionTipLane == .dormant
        )
    }

    var recoverySection: some View {
        StallyReviewLaneSection(
            selection: $selectionState.recovery,
            configuration: .init(
                title: StallyLocalization.string("Recovery Candidates"),
                supporting: StallyLocalization.string(
                    "Archived items with enough history that they may deserve another turn."
                ),
                emptyMessage: StallyLocalization.string("Archive is quiet for now."),
                itemActionTitle: StallyLocalization.string("Move Back to Home"),
                bulkActionTitle: StallyLocalization.string("Move Back to Home"),
                confirmationTitle: StallyLocalization.string(
                    "Move Selected Items Back to Home"
                ),
                confirmationMessage: { count in
                    StallyLocalization.format(
                        "Move %lld archived items back into Home?",
                        count
                    )
                },
                confirmationButtonTitle: StallyLocalization.string("Move Back to Home"),
                confirmationButtonRole: nil
            ),
            items: recoveryCandidateItems,
            snapshotsByID: snapshotsByID,
            onOpenItem: onOpenItem,
            onItemAction: onUnarchiveItem,
            onBulkAction: onUnarchiveItems,
            itemLinkURL: itemLinkURL(for:),
            showsSelectionTip: selectionTipLane == .recovery
        )
    }

    func itemLinkURL(
        for item: Item
    ) -> URL? {
        StallyDeepLinking.codec().preferredURL(
            for: .item(item.id)
        )
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(StallySampleData())) {
    @Previewable @Query var items: [Item]

    NavigationStack {
        StallyReviewView(
            items: items,
            preferences: .init(),
            onArchiveItem: { _ in
                // no-op
            },
            onArchiveItems: { _ in
                // no-op
            },
            onUnarchiveItem: { _ in
                // no-op
            },
            onUnarchiveItems: { _ in
                // no-op
            },
            onOpenItem: { _ in
                // no-op
            }
        )
    }
}
