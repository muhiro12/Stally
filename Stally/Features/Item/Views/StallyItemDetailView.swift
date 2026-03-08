import MHDeepLinking
import MHUI
import StallyLibrary
import SwiftData
import SwiftUI

struct StallyItemDetailView: View {
    @Environment(\.mhTheme)
    private var theme
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @State private var isHistoryEditorPresented = false
    @State private var selectedHistoryDate = Date.now

    let item: Item
    let onEdit: (UUID) -> Void
    let onToggleTodayMark: (Item) -> Void
    let onToggleArchiveState: (Item) -> Void
    let onSetMarkState: (Item, Date, Bool) -> Bool

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.section) {
            heroSection
            actionSection

            if let note = item.note {
                noteSection(note: note)
            }

            StallyHistorySection(
                months: MarkHistoryCalculator.months(for: item)
            )
            .mhSection(
                title: Text("Quiet History"),
                supporting: Text("One filled day means you chose this item on that date.")
            )
        }
        .mhScreen(
            title: nil as Text?,
            subtitle: nil as Text?
        )
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isHistoryEditorPresented) {
            historyEditorSheet
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    onEdit(item.id)
                }
            }
        }
    }
}

private extension StallyItemDetailView {
    var summary: ItemSummary {
        ItemInsightsCalculator.summary(for: item)
    }

    var selectedDateSummary: ItemSummary {
        ItemInsightsCalculator.summary(
            for: item,
            referenceDate: selectedHistoryDate
        )
    }

    var historyDateRange: ClosedRange<Date> {
        item.createdAt...Date.now
    }

    var usesCompactLayout: Bool {
        horizontalSizeClass != .regular
    }

    var itemShareURL: URL? {
        StallyDeepLinking.codec().preferredURL(
            for: .item(item.id)
        )
    }

    var heroSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.group) {
            heroContent

            if item.isArchived {
                Label(
                    "Archived items stay out of Home until you move them back.",
                    systemImage: "archivebox.fill"
                )
                .mhRowSupporting()
            }
        }
        .mhSection(
            title: Text("Overview"),
            supporting: Text("Marks accumulate one day at a time.")
        )
    }

    @ViewBuilder
    var heroContent: some View {
        if usesCompactLayout {
            VStack(alignment: .leading, spacing: theme.spacing.group) {
                heroArtwork
                heroTextBlock
            }
        } else {
            HStack(alignment: .top, spacing: theme.spacing.group) {
                heroArtwork
                heroTextBlock
                Spacer(minLength: .zero)
            }
        }
    }

    var heroArtwork: some View {
        StallyItemArtworkView(
            photoData: item.photoData,
            category: item.category,
            width: 132,
            height: 164
        )
    }

    var heroTextBlock: some View {
        VStack(alignment: .leading, spacing: theme.spacing.group) {
            Text(item.name)
                .font(.system(size: 28, weight: .semibold, design: .serif))

            Text(item.category.title)
                .mhBadge(style: .accent)

            VStack(alignment: .leading, spacing: theme.spacing.control) {
                LabeledContent("Total marks", value: "\(summary.totalMarks)")
                    .labeledContentStyle(.mhKeyValue)
                LabeledContent(
                    "Last marked",
                    value: summary.lastMarkedAt?.formatted(date: .abbreviated, time: .omitted)
                        ?? "Not yet"
                )
                .labeledContentStyle(.mhKeyValue)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var actionSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            toggleTodayMarkButton
            toggleArchiveStateButton

            if let itemShareURL {
                shareButton(url: itemShareURL)
            }

            historyEditorButton
        }
        .mhSection(
            title: Text("Actions"),
            supporting: Text("Mark the item for today or move it in and out of Archive without affecting past marks.")
        )
    }

    var toggleTodayMarkButton: some View {
        Button {
            onToggleTodayMark(item)
        } label: {
            Label(
                summary.isMarkedToday ? "Undo Today’s Mark" : "Mark Today",
                systemImage: summary.isMarkedToday ? "checkmark.circle.fill" : "circle.fill"
            )
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(
            .mhAction(summary.isMarkedToday ? .secondary : .primary)
        )
        .disabled(item.isArchived)
    }

    var toggleArchiveStateButton: some View {
        Button {
            onToggleArchiveState(item)
        } label: {
            Label(
                item.isArchived ? "Move Back to Home" : "Archive Item",
                systemImage: item.isArchived ? "tray.and.arrow.up.fill" : "archivebox.fill"
            )
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.mhSecondary)
    }

    var historyEditorButton: some View {
        Button(action: openHistoryEditor) {
            Label(
                item.isArchived ? "Review Another Day" : "Adjust Another Day",
                systemImage: "calendar.badge.clock"
            )
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.mhSecondary)
    }

    var historyEditorSheet: some View {
        NavigationStack {
            Form {
                historyDateSection
                selectedDaySection
                historyActionSection
            }
            .navigationTitle("Adjust History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        isHistoryEditorPresented = false
                    }
                }
            }
        }
    }

    var historyDateSection: some View {
        Section("Day") {
            DatePicker(
                "Date",
                selection: $selectedHistoryDate,
                in: historyDateRange,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
        }
    }

    @ViewBuilder
    var selectedDaySection: some View {
        Section("Selected Day") {
            LabeledContent(
                "Date",
                value: selectedHistoryDate.formatted(
                    date: .abbreviated,
                    time: .omitted
                )
            )
            LabeledContent(
                "Current State",
                value: selectedDateSummary.isMarkedToday ? "Marked" : "Not marked"
            )
            .foregroundStyle(
                selectedDateSummary.isMarkedToday ? StallyDesign.tint : .secondary
            )

            if item.isArchived {
                Text("Archived items are read-only. Move this item back to Home to change history.")
                    .mhRowSupporting()
            }
        }
    }

    var historyActionSection: some View {
        Section {
            Button {
                applyHistoryChange()
            } label: {
                Text(selectedDateSummary.isMarkedToday ? "Remove Mark" : "Add Mark")
                    .frame(maxWidth: .infinity)
            }
            .disabled(item.isArchived)
        }
    }

    func shareButton(
        url: URL
    ) -> some View {
        ShareLink(item: url) {
            Label(
                "Share Item Link",
                systemImage: "square.and.arrow.up"
            )
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.mhSecondary)
    }

    func noteSection(
        note: String
    ) -> some View {
        Text(note)
            .frame(maxWidth: .infinity, alignment: .leading)
            .mhSection(title: Text("Note"))
    }

    func openHistoryEditor() {
        let defaultDate = summary.lastMarkedAt ?? Date.now
        selectedHistoryDate = min(
            max(defaultDate, item.createdAt),
            Date.now
        )
        isHistoryEditorPresented = true
    }

    func applyHistoryChange() {
        let shouldBeMarked = !selectedDateSummary.isMarkedToday
        let didSucceed = onSetMarkState(
            item,
            selectedHistoryDate,
            shouldBeMarked
        )

        if didSucceed {
            isHistoryEditorPresented = false
        }
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(StallySampleData())) {
    @Previewable @Query var items: [Item]

    NavigationStack {
        if let item = ItemInsightsCalculator.activeItems(from: items).first {
            StallyItemDetailView(
                item: item,
                onEdit: { _ in
                    // no-op
                },
                onToggleTodayMark: { _ in
                    // no-op
                },
                onToggleArchiveState: { _ in
                    // no-op
                },
                onSetMarkState: { _, _, _ in
                    true
                }
            )
        } else {
            EmptyView()
        }
    }
}
