import StallyLibrary
import SwiftUI
import TipKit
import UIKit

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
        VStack(alignment: .leading, spacing: 14) {
            StallySectionHeader(
                eyebrow: nil,
                title: configuration.title,
                subtitle: configuration.supporting
            )

            if items.isEmpty {
                Text(configuration.emptyMessage)
                    .font(StallyDesign.Typography.caption)
                    .foregroundStyle(StallyDesign.Palette.mutedInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .stallyPanel(.quiet)
            } else {
                selectionControls

                ForEach(items, id: \.id) { item in
                    if selection.isSelectionModeEnabled {
                        selectableReviewRow(item: item)
                    } else {
                        actionableReviewRow(item: item)
                    }
                }
            }
        }
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
            Text(configuration.confirmationMessage(selectedItems.count))
        }
    }
}

private extension StallyReviewLaneSection {
    var selectedItems: [Item] {
        items.filter { item in
            selection.selectedItemIDs.contains(item.id)
        }
    }

    var selectionControls: some View {
        HStack(spacing: 12) {
            Button(
                selection.isSelectionModeEnabled
                    ? StallyLocalization.string("Done")
                    : StallyLocalization.string("Select")
            ) {
                selection.toggleSelectionMode()
            }
            .buttonStyle(StallySecondaryButtonStyle())
            .popoverTip(selectionTip, arrowEdge: .bottom)

            if selection.isSelectionModeEnabled {
                Text(
                    StallyLocalization.format(
                        "%lld selected",
                        selectedItems.count
                    )
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(StallyDesign.Palette.mutedInk)

                Spacer(minLength: .zero)

                Button(configuration.bulkActionTitle) {
                    selection.requestBulkAction()
                }
                .buttonStyle(StallyPrimaryButtonStyle())
                .disabled(selectedItems.isEmpty)
            }
        }
        .stallyPanel(.elevated, padding: 12)
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
        VStack(alignment: .leading, spacing: 12) {
            reviewRow(item: item)

            Button(configuration.itemActionTitle) {
                onItemAction(item)
            }
            .buttonStyle(StallySecondaryButtonStyle())
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
                        ? StallyDesign.Palette.accent
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

        return HStack(spacing: 16) {
            StallyItemArtworkView(
                photoData: item.photoData,
                category: item.category,
                width: 68,
                height: 82
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(item.name)
                    .font(StallyDesign.Typography.cardTitle)
                    .foregroundStyle(StallyDesign.Palette.ink)

                StallyTag(
                    title: item.category.title,
                    tone: .elevated
                )

                Text(
                    rowSupportingText(
                        summary: summary,
                        snapshot: snapshot
                    )
                )
                .font(StallyDesign.Typography.caption)
                .foregroundStyle(StallyDesign.Palette.mutedInk)
            }

            Spacer(minLength: .zero)

            trailingView()
                .font(.title3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .stallyPanel(.base)
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
