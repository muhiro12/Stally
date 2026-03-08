import MHUI
import StallyLibrary
import SwiftUI
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

    @Environment(\.mhTheme)
    private var theme

    @Binding var selection: StallyReviewSelectionState.LaneSelection

    let configuration: Configuration
    let items: [Item]
    let snapshotsByID: [UUID: ItemReviewSnapshot]
    let onOpenItem: (UUID) -> Void
    let onItemAction: (Item) -> Void
    let onBulkAction: ([Item]) -> Void
    let itemLinkURL: (Item) -> URL?

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
        HStack(spacing: theme.spacing.control) {
            Button(selection.isSelectionModeEnabled ? "Done" : "Select") {
                selection.toggleSelectionMode()
            }
            .buttonStyle(.mhSecondary)

            if selection.isSelectionModeEnabled {
                Text("\(selectedItems.count) selected")
                    .mhRowSupporting()

                Spacer(minLength: .zero)

                Button(configuration.bulkActionTitle) {
                    selection.requestBulkAction()
                }
                .buttonStyle(.mhPrimary)
                .disabled(selectedItems.isEmpty)
            }
        }
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
            return "\(summary.totalMarks) marks • last used \(daysSinceLastMark)d ago"
        }

        if let daysSinceCreated = snapshot?.daysSinceCreated {
            return "\(summary.totalMarks) marks • added \(daysSinceCreated)d ago"
        }

        return "\(summary.totalMarks) marks"
    }

    func performBulkAction() {
        guard !selectedItems.isEmpty else {
            return
        }

        onBulkAction(selectedItems)
        selection.completeBulkAction()
    }
}
