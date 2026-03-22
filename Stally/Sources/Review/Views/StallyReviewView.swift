import MHDeepLinking
import MHUI
import StallyLibrary
import SwiftData
import SwiftUI

struct StallyReviewView: View {
    @Environment(StallyAppModel.self)
    private var appModel
    @Environment(\.modelContext)
    private var context
    @Environment(\.stallyMHUIThemeMetrics)
    private var theme
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @State private var screenModel: StallyReviewScreenModel

    let snapshot: StallyReviewSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.group) {
            summaryCard

            if snapshot.summary.totalReviewCount == .zero, !screenModel.showsCompletedSections {
                emptyState
            } else {
                if screenModel.shouldShowUntouchedSection {
                    untouchedSection
                }

                if screenModel.shouldShowDormantSection {
                    dormantSection
                }

                if screenModel.shouldShowRecoverySection {
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Settings", systemImage: "gearshape") {
                    appModel.openSettings(in: .review)
                }
            }
        }
        .task(
            id: [
                snapshot.syncKey,
                appModel.reviewPreferences.showCompletedSections ? "1" : "0",
            ].joined(separator: "#")
        ) {
            screenModel.update(
                snapshot: snapshot,
                showsCompletedSections: appModel.reviewPreferences.showCompletedSections
            )
        }
    }

    init(
        snapshot: StallyReviewSnapshot
    ) {
        self.snapshot = snapshot
        _screenModel = State(
            initialValue: .init(
                snapshot: snapshot,
                showsCompletedSections: false
            )
        )
    }
}

private extension StallyReviewView {
    var usesCompactLayout: Bool {
        horizontalSizeClass != .regular
    }

    var untouchedSelectionBinding: Binding<StallyReviewSelectionState.LaneSelection> {
        .init(
            get: {
                screenModel.selectionState.untouched
            },
            set: { newValue in
                screenModel.selectionState.untouched = newValue
            }
        )
    }

    var dormantSelectionBinding: Binding<StallyReviewSelectionState.LaneSelection> {
        .init(
            get: {
                screenModel.selectionState.dormant
            },
            set: { newValue in
                screenModel.selectionState.dormant = newValue
            }
        )
    }

    var recoverySelectionBinding: Binding<StallyReviewSelectionState.LaneSelection> {
        .init(
            get: {
                screenModel.selectionState.recovery
            },
            set: { newValue in
                screenModel.selectionState.recovery = newValue
            }
        )
    }

    var summaryCard: some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            HStack(alignment: .firstTextBaseline) {
                Text("Review Snapshot")
                    .mhRowTitle()

                Spacer(minLength: theme.spacing.control)

                Text("\(snapshot.summary.totalReviewCount)")
                    .mhRowValue(colorRole: .accent)
            }

            Text("This brings together first-use lag, inactivity, and archive recovery into one review lane.")
                .mhRowSupporting()

            StallyMetricGrid(
                metrics: screenModel.summaryMetrics,
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
            selection: untouchedSelectionBinding,
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
            items: screenModel.untouchedItems,
            snapshotsByID: screenModel.snapshotsByID,
            onOpenItem: openItem(_:),
            onItemAction: archiveItem(_:),
            onBulkAction: archiveItems(_:),
            itemLinkURL: itemLinkURL(for:),
            showsSelectionTip: screenModel.selectionTipLane == .untouched
        )
    }

    var dormantSection: some View {
        StallyReviewLaneSection(
            selection: dormantSelectionBinding,
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
            items: screenModel.dormantItems,
            snapshotsByID: screenModel.snapshotsByID,
            onOpenItem: openItem(_:),
            onItemAction: archiveItem(_:),
            onBulkAction: archiveItems(_:),
            itemLinkURL: itemLinkURL(for:),
            showsSelectionTip: screenModel.selectionTipLane == .dormant
        )
    }

    var recoverySection: some View {
        StallyReviewLaneSection(
            selection: recoverySelectionBinding,
            configuration: .init(
                title: StallyLocalization.string("Recovery Candidates"),
                supporting: StallyLocalization.string(
                    "Archived items whose history suggests they may deserve another turn."
                ),
                emptyMessage: StallyLocalization.string("Nothing is asking to come back right now."),
                itemActionTitle: StallyLocalization.string("Move Back to Library"),
                bulkActionTitle: StallyLocalization.string("Move Back to Library"),
                confirmationTitle: StallyLocalization.string("Move Back to Library"),
                confirmationMessage: { count in
                    StallyLocalization.format(
                        "Move %lld items back into the main library?",
                        count
                    )
                },
                confirmationButtonTitle: StallyLocalization.string("Move Back to Library"),
                confirmationButtonRole: nil
            ),
            items: screenModel.recoveryCandidateItems,
            snapshotsByID: screenModel.snapshotsByID,
            onOpenItem: openItem(_:),
            onItemAction: unarchiveItem(_:),
            onBulkAction: unarchiveItems(_:),
            itemLinkURL: itemLinkURL(for:),
            showsSelectionTip: screenModel.selectionTipLane == .recovery
        )
    }

    func openItem(
        _ itemID: UUID
    ) {
        appModel.openItem(
            itemID,
            in: .review
        )
    }

    func archiveItem(
        _ item: Item
    ) {
        appModel.performAction {
            try StallyAppActionService.archive(
                context: context,
                item: item
            )
        }
    }

    func archiveItems(
        _ items: [Item]
    ) {
        appModel.performAction {
            try StallyAppActionService.archive(
                context: context,
                items: items
            )
        }
    }

    func unarchiveItem(
        _ item: Item
    ) {
        appModel.performAction {
            try StallyAppActionService.unarchive(
                context: context,
                item: item
            )
        }
    }

    func unarchiveItems(
        _ items: [Item]
    ) {
        appModel.performAction {
            try StallyAppActionService.unarchive(
                context: context,
                items: items
            )
        }
    }

    func itemLinkURL(
        for item: Item
    ) -> URL? {
        StallyDeepLinking.codec().preferredURL(
            for: .item(item.id)
        )
    }
}

@available(iOS 26.0, *)
#Preview(traits: .modifier(StallySampleData())) {
    @Previewable @Query var items: [Item]

    NavigationStack {
        StallyReviewView(
            snapshot: StallyReviewSnapshotBuilder.build(
                items: items,
                preferences: .init()
            )
        )
    }
}
