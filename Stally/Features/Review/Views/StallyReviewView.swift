import MHUI
import StallyLibrary
import SwiftData
import SwiftUI

struct StallyReviewView: View {
    @Environment(\.mhTheme)
    private var theme

    @State private var isUntouchedSelectionModeEnabled = false
    @State private var selectedUntouchedItemIDs: Set<UUID> = []
    @State private var isUntouchedBulkArchiveConfirmationPresented = false
    @State private var isDormantSelectionModeEnabled = false
    @State private var selectedDormantItemIDs: Set<UUID> = []
    @State private var isDormantBulkArchiveConfirmationPresented = false

    let items: [Item]
    let policy: ItemReviewPolicy
    let onArchiveItem: (Item) -> Void
    let onArchiveItems: ([Item]) -> Void
    let onUnarchiveItem: (Item) -> Void
    let onOpenItem: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.group) {
            summaryCard

            if summary.totalReviewCount == .zero {
                emptyState
            } else {
                if !untouchedItems.isEmpty {
                    untouchedSection
                }

                if !dormantItems.isEmpty {
                    dormantSection
                }

                if !recoveryCandidateItems.isEmpty {
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
        .confirmationDialog(
            "Archive Selected Items",
            isPresented: $isUntouchedBulkArchiveConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Archive Selected", role: .destructive) {
                archiveSelectedUntouchedItems()
            }
            Button("Cancel", role: .cancel) {
                // no-op
            }
        } message: {
            Text("Archive \(selectedUntouchedItems.count) items that still have no marks?")
        }
        .confirmationDialog(
            "Archive Selected Items",
            isPresented: $isDormantBulkArchiveConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Archive Selected", role: .destructive) {
                archiveSelectedDormantItems()
            }
            Button("Cancel", role: .cancel) {
                // no-op
            }
        } message: {
            Text("Archive \(selectedDormantItems.count) dormant items and move them into Recovery Candidates?")
        }
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

    var selectedUntouchedItems: [Item] {
        untouchedItems.filter { item in
            selectedUntouchedItemIDs.contains(item.id)
        }
    }

    var selectedDormantItems: [Item] {
        dormantItems.filter { item in
            selectedDormantItemIDs.contains(item.id)
        }
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

    var untouchedSection: some View {
        reviewSection(
            title: "Needs First Mark",
            supporting: "Items that have been waiting quietly without a first mark.",
            items: untouchedItems
        ) {
            untouchedSelectionControls
        } rowContent: { item in
            if isUntouchedSelectionModeEnabled {
                selectableReviewRow(
                    item: item,
                    isSelected: selectedUntouchedItemIDs.contains(item.id),
                    onToggleSelection: toggleUntouchedSelection(for:)
                )
            } else {
                actionableReviewRow(
                    item: item,
                    actionTitle: "Archive Item",
                    onItemAction: onArchiveItem
                )
            }
        }
    }

    var untouchedSelectionControls: some View {
        HStack(spacing: theme.spacing.control) {
            Button(isUntouchedSelectionModeEnabled ? "Done" : "Select") {
                toggleUntouchedSelectionMode()
            }
            .buttonStyle(.mhSecondary)

            if isUntouchedSelectionModeEnabled {
                Text("\(selectedUntouchedItems.count) selected")
                    .mhRowSupporting()

                Spacer(minLength: .zero)

                Button("Archive Selected") {
                    isUntouchedBulkArchiveConfirmationPresented = true
                }
                .buttonStyle(.mhPrimary)
                .disabled(selectedUntouchedItems.isEmpty)
            }
        }
    }

    var dormantSection: some View {
        reviewSection(
            title: "Dormant",
            supporting: "Items whose last mark feels far enough away to revisit.",
            items: dormantItems
        ) {
            dormantSelectionControls
        } rowContent: { item in
            if isDormantSelectionModeEnabled {
                selectableReviewRow(
                    item: item,
                    isSelected: selectedDormantItemIDs.contains(item.id),
                    onToggleSelection: toggleDormantSelection(for:)
                )
            } else {
                actionableReviewRow(
                    item: item,
                    actionTitle: "Archive Item",
                    onItemAction: onArchiveItem
                )
            }
        }
    }

    var recoverySection: some View {
        reviewSection(
            title: "Recovery Candidates",
            supporting: "Archived items with enough history that they may deserve another turn.",
            items: recoveryCandidateItems
        ) { item in
            actionableReviewRow(
                item: item,
                actionTitle: "Move Back to Home",
                onItemAction: onUnarchiveItem
            )
        }
    }

    var dormantSelectionControls: some View {
        HStack(spacing: theme.spacing.control) {
            Button(isDormantSelectionModeEnabled ? "Done" : "Select") {
                toggleDormantSelectionMode()
            }
            .buttonStyle(.mhSecondary)

            if isDormantSelectionModeEnabled {
                Text("\(selectedDormantItems.count) selected")
                    .mhRowSupporting()

                Spacer(minLength: .zero)

                Button("Archive Selected") {
                    isDormantBulkArchiveConfirmationPresented = true
                }
                .buttonStyle(.mhPrimary)
                .disabled(selectedDormantItems.isEmpty)
            }
        }
    }

    func reviewSection<RowContent: View>(
        title: String,
        supporting: String,
        items: [Item],
        @ViewBuilder rowContent: @escaping (Item) -> RowContent
    ) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            ForEach(items, id: \.id) { item in
                rowContent(item)
            }
        }
        .mhSection(
            title: Text(title),
            supporting: Text(supporting)
        )
    }

    func reviewSection<Controls: View, RowContent: View>(
        title: String,
        supporting: String,
        items: [Item],
        @ViewBuilder controls: () -> Controls,
        @ViewBuilder rowContent: @escaping (Item) -> RowContent
    ) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            controls()

            ForEach(items, id: \.id) { item in
                rowContent(item)
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

    func selectableReviewRow(
        item: Item,
        isSelected: Bool,
        onToggleSelection: @escaping (Item) -> Void
    ) -> some View {
        Button {
            onToggleSelection(item)
        } label: {
            reviewRowContent(item: item) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
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

                Text(rowSupportingText(summary: summary, snapshot: snapshot))
                    .mhRowSupporting()
            }

            Spacer(minLength: .zero)

            trailingView()
                .font(.title3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .mhSurfaceInset()
        .mhSurface()
    }

    func toggleUntouchedSelectionMode() {
        isUntouchedSelectionModeEnabled.toggle()

        if !isUntouchedSelectionModeEnabled {
            selectedUntouchedItemIDs.removeAll()
        }
    }

    func toggleUntouchedSelection(
        for item: Item
    ) {
        if selectedUntouchedItemIDs.contains(item.id) {
            selectedUntouchedItemIDs.remove(item.id)
        } else {
            selectedUntouchedItemIDs.insert(item.id)
        }
    }

    func archiveSelectedUntouchedItems() {
        let itemsToArchive = selectedUntouchedItems

        guard !itemsToArchive.isEmpty else {
            return
        }

        onArchiveItems(itemsToArchive)
        selectedUntouchedItemIDs.removeAll()
        isUntouchedSelectionModeEnabled = false
    }

    func toggleDormantSelectionMode() {
        isDormantSelectionModeEnabled.toggle()

        if !isDormantSelectionModeEnabled {
            selectedDormantItemIDs.removeAll()
        }
    }

    func toggleDormantSelection(
        for item: Item
    ) {
        if selectedDormantItemIDs.contains(item.id) {
            selectedDormantItemIDs.remove(item.id)
        } else {
            selectedDormantItemIDs.insert(item.id)
        }
    }

    func archiveSelectedDormantItems() {
        let itemsToArchive = selectedDormantItems

        guard !itemsToArchive.isEmpty else {
            return
        }

        onArchiveItems(itemsToArchive)
        selectedDormantItemIDs.removeAll()
        isDormantSelectionModeEnabled = false
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
            onArchiveItems: { _ in
                // no-op
            },
            onUnarchiveItem: { _ in
                // no-op
            },
            onOpenItem: { _ in
                // no-op
            }
        )
    }
}
