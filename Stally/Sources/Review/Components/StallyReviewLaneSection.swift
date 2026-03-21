import MHUI
import StallyLibrary
import SwiftUI
import TipKit
import UIKit

private enum StallyReviewSelectionControlID: String, Sendable {
    case selectionMode
    case bulkAction
}

struct StallyReviewLaneSection: View {
    struct Configuration {
        let title: String
        let supporting: String
        let emptyMessage: String
        let itemActionTitle: String
        let bulkActionTitle: String
        let confirmationTitle: String
        let confirmationMessage: (Int) -> String
        let confirmationButtonTitle: String
        let confirmationButtonRole: ButtonRole?
    }

    @Environment(\.mhTheme)
    private var theme

    @Namespace private var selectionControlNamespace

    @Binding var selection: StallyReviewSelectionState.LaneSelection

    let configuration: Configuration
    let items: [Item]
    let snapshotsByID: [UUID: ItemReviewSnapshot]
    let onOpenItem: (UUID) -> Void
    let onItemAction: (Item) -> Void
    let onBulkAction: ([Item]) -> Void
    let itemLinkURL: (Item) -> URL?
    let showsSelectionTip: Bool

    var body: some View {
        content
            .confirmationDialog(
                configuration.confirmationTitle,
                isPresented: $selection.isBulkConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button(
                    configuration.confirmationButtonTitle,
                    role: configuration.confirmationButtonRole
                ) {
                    performBulkAction()
                }
                Button("Cancel", role: .cancel) {
                    selection.cancelBulkAction()
                }
            } message: {
                Text(
                    configuration.confirmationMessage(selectedItems.count)
                )
            }
    }
}

private extension StallyReviewLaneSection {
    @ViewBuilder
    var content: some View {
        if items.isEmpty {
            Text(configuration.emptyMessage)
                .mhRowSupporting()
                .frame(maxWidth: .infinity, alignment: .leading)
                .mhSurfaceInset()
                .mhSurface(role: .muted)
                .mhSection(
                    title: Text(configuration.title),
                    supporting: Text(configuration.supporting)
                )
        } else {
            VStack(alignment: .leading, spacing: theme.spacing.control) {
                selectionControls

                ForEach(items, id: \.id) { item in
                    if selection.isSelectionModeEnabled {
                        selectableReviewRow(item: item)
                    } else {
                        actionableReviewRow(item: item)
                    }
                }
            }
            .mhSection(
                title: Text(configuration.title),
                supporting: Text(configuration.supporting)
            )
        }
    }

    var selectedItems: [Item] {
        items.filter { item in
            selection.selectedItemIDs.contains(item.id)
        }
    }

    var selectionControls: some View {
        MHGlassContainer(spacing: theme.spacing.control) {
            HStack(spacing: theme.spacing.control) {
                Button(
                    selection.isSelectionModeEnabled
                        ? StallyLocalization.string("Done")
                        : StallyLocalization.string("Select")
                ) {
                    selection.toggleSelectionMode()
                }
                .buttonStyle(.mhSecondary)
                .mhGlassEffectID(
                    StallyReviewSelectionControlID.selectionMode,
                    in: selectionControlNamespace
                )
                .popoverTip(selectionTip, arrowEdge: .bottom)

                if selection.isSelectionModeEnabled {
                    Text(
                        StallyLocalization.format(
                            "%lld selected",
                            selectedItems.count
                        )
                    )
                    .mhRowSupporting()

                    Spacer(minLength: .zero)

                    Button(configuration.bulkActionTitle) {
                        selection.requestBulkAction()
                    }
                    .buttonStyle(.mhPrimary)
                    .mhGlassEffectID(
                        StallyReviewSelectionControlID.bulkAction,
                        in: selectionControlNamespace
                    )
                    .disabled(selectedItems.isEmpty)
                }
            }
        }
    }

    var selectionTip: (any Tip)? {
        guard showsSelectionTip,
              selection.isSelectionModeEnabled == false,
              items.count >= 2 else {
            return nil
        }

        return StallyTips.ReviewBulkSelectTip()
    }

    func actionableReviewRow(
        item: Item
    ) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            reviewRow(item: item)

            Button(configuration.itemActionTitle) {
                onItemAction(item)
            }
            .buttonStyle(.mhSecondary)
        }
    }

    func selectableReviewRow(
        item: Item
    ) -> some View {
        Button {
            selection.toggleSelection(for: item.id)
        } label: {
            reviewRowContent(item: item) {
                Image(
                    systemName: selection.selectedItemIDs.contains(item.id)
                        ? "checkmark.circle.fill"
                        : "circle"
                )
                .foregroundStyle(
                    selection.selectedItemIDs.contains(item.id)
                        ? Color.accentColor
                        : .secondary
                )
            }
        }
        .buttonStyle(.plain)
    }

    func reviewRow(
        item: Item
    ) -> some View {
        Button {
            onOpenItem(item.id)
        } label: {
            reviewRowContent(item: item) {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    func reviewRowContent<TrailingView: View>(
        item: Item,
        @ViewBuilder trailingView: () -> TrailingView
    ) -> some View {
        let summary = ItemInsightsCalculator.summary(for: item)
        let snapshot = snapshotsByID[item.id]

        return HStack(spacing: theme.spacing.group) {
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

                Text(
                    rowSupportingText(
                        summary: summary,
                        snapshot: snapshot
                    )
                )
                .mhRowSupporting()
            }

            Spacer(minLength: .zero)

            trailingView()
                .font(.title3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .mhSurfaceInset()
        .mhSurface()
        .contextMenu {
            if let itemLinkURL = itemLinkURL(item) {
                Button("Copy Item Link", systemImage: "link") {
                    UIPasteboard.general.url = itemLinkURL
                }
            }
        }
    }

    func rowSupportingText(
        summary: ItemSummary,
        snapshot: ItemReviewSnapshot?
    ) -> String {
        if let daysSinceLastMark = snapshot?.daysSinceLastMark {
            return StallyLocalization.format(
                "%1$lld marks | last used %2$lldd ago",
                summary.totalMarks,
                daysSinceLastMark
            )
        }

        if let daysSinceCreated = snapshot?.daysSinceCreated {
            return StallyLocalization.format(
                "%1$lld marks | added %2$lldd ago",
                summary.totalMarks,
                daysSinceCreated
            )
        }

        return StallyLocalization.format(
            "%lld marks",
            summary.totalMarks
        )
    }

    func performBulkAction() {
        guard !selectedItems.isEmpty else {
            return
        }

        onBulkAction(selectedItems)
        selection.completeBulkAction()
    }
}
