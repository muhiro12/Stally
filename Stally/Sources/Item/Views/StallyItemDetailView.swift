import MHDeepLinking
import StallyLibrary
import SwiftData
import SwiftUI
import TipKit

struct StallyItemDetailView: View {
    @Environment(StallyAppModel.self)
    private var appModel
    @Environment(\.modelContext)
    private var context
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @State private var isHistoryEditorPresented = false
    @State private var selectedHistoryDate = Date.now

    let item: Item
    let navigationNamespace: Namespace.ID

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StallyDesign.Layout.sectionSpacing) {
                heroSection
                actionsSection
                insightsSection

                if let note = item.note {
                    noteSection(note)
                }

                historySection
            }
            .padding(.horizontal, StallyDesign.Layout.screenPadding)
            .padding(.top, 12)
            .safeAreaPadding(.bottom, 28)
        }
        .contentMargins(.bottom, 28, for: .scrollContent)
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTransition(
            .zoom(
                sourceID: item.id,
                in: navigationNamespace
            )
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    appModel.presentEditEditor(item.id)
                }
            }
        }
        .sheet(isPresented: $isHistoryEditorPresented) {
            historyEditorSheet
        }
        .stallyScreenBackground()
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

    var usesCompactLayout: Bool {
        horizontalSizeClass != .regular
    }

    var historyDateRange: ClosedRange<Date> {
        item.createdAt...Date.now
    }

    var itemShareURL: URL? {
        StallyDeepLinking.codec().preferredURL(
            for: .item(item.id)
        )
    }

    var heroSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            if usesCompactLayout {
                VStack(alignment: .leading, spacing: 18) {
                    artwork
                    heroText
                }
            } else {
                HStack(alignment: .top, spacing: 18) {
                    artwork
                    heroText
                    Spacer(minLength: .zero)
                }
            }

            if item.isArchived {
                Label(
                    "Archived items stay out of the active library until you move them back.",
                    systemImage: "archivebox.fill"
                )
                .font(StallyDesign.Typography.caption)
                .foregroundStyle(StallyDesign.Palette.mutedInk)
            }
        }
        .stallyPanel(.base)
    }

    var artwork: some View {
        StallyItemArtworkView(
            photoData: item.photoData,
            category: item.category,
            width: 148,
            height: 182
        )
    }

    var heroText: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(item.name)
                .font(StallyDesign.Typography.hero)
                .foregroundStyle(StallyDesign.Palette.ink)

            StallyTag(
                title: item.category.title,
                tone: .elevated
            )

            VStack(alignment: .leading, spacing: 10) {
                detailRow(
                    title: "Total marks",
                    value: "\(summary.totalMarks)"
                )
                detailRow(
                    title: "Last marked",
                    value: summary.lastMarkedAt?.formatted(
                        date: .abbreviated,
                        time: .omitted
                    ) ?? StallyLocalization.string("Not yet")
                )
                detailRow(
                    title: "Days since last",
                    value: daysSinceLastMarkTitle
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func detailRow(
        title: String,
        value: String
    ) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(StallyDesign.Typography.caption)
                .foregroundStyle(StallyDesign.Palette.mutedInk)

            Spacer(minLength: 12)

            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(StallyDesign.Palette.ink)
        }
    }

    var actionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StallySectionHeader(
                eyebrow: "Actions",
                title: "Act on the item without leaving detail",
                subtitle: "Today’s mark, archive state, sharing, and history adjustment all live here."
            )

            if summary.isMarkedToday {
                Button {
                    appModel.performAction {
                        try StallyAppActionService.toggleTodayMark(
                            context: context,
                            item: item
                        )
                    }
                } label: {
                    Label(
                        "Undo Today's Mark",
                        systemImage: "checkmark.circle.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(StallySecondaryButtonStyle())
                .disabled(item.isArchived)
            } else {
                Button {
                    appModel.performAction {
                        try StallyAppActionService.toggleTodayMark(
                            context: context,
                            item: item
                        )
                    }
                } label: {
                    Label(
                        "Mark Today",
                        systemImage: "circle.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(StallyPrimaryButtonStyle())
                .disabled(item.isArchived)
            }

            Button {
                appModel.performAction {
                    try StallyAppActionService.toggleArchiveState(
                        context: context,
                        item: item
                    )
                }
            } label: {
                Label(
                    item.isArchived
                        ? "Move Back to Library"
                        : "Archive Item",
                    systemImage: item.isArchived
                        ? "tray.and.arrow.up.fill"
                        : "archivebox.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(StallySecondaryButtonStyle())

            if let itemShareURL {
                ShareLink(item: itemShareURL) {
                    Label("Share Item Link", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(StallySecondaryButtonStyle())
            }

            Button {
                openHistoryEditor()
            } label: {
                Label(
                    item.isArchived
                        ? "Review Another Day"
                        : "Adjust Another Day",
                    systemImage: "calendar.badge.clock"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(StallySecondaryButtonStyle())
            .popoverTip(adjustHistoryTip, arrowEdge: .top)
        }
        .stallyPanel(.base)
    }

    var insightsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StallySectionHeader(
                eyebrow: "Insights",
                title: "A tighter read on this one item",
                subtitle: "Use the recent windows to judge whether the item is current, fading, or mostly historical."
            )

            StallyMetricGrid(
                metrics: insightMetrics,
                usesCompactLayout: usesCompactLayout
            )
        }
        .stallyPanel(.base)
    }

    func noteSection(
        _ note: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            StallySectionHeader(
                eyebrow: "Note",
                title: "Saved context",
                subtitle: nil
            )

            Text(note)
                .font(StallyDesign.Typography.body)
                .foregroundStyle(StallyDesign.Palette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .stallyPanel(.base)
    }

    var historySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StallySectionHeader(
                eyebrow: "History",
                title: "Quiet history",
                subtitle: "One filled day means you chose this item on that date."
            )

            StallyHistorySection(
                months: MarkHistoryCalculator.months(for: item)
            )
        }
        .stallyPanel(.base)
    }

    var historyEditorSheet: some View {
        NavigationStack {
            Form {
                Section("Day") {
                    DatePicker(
                        "Date",
                        selection: $selectedHistoryDate,
                        in: historyDateRange,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                }

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
                        value: selectedDateSummary.isMarkedToday
                            ? StallyLocalization.string("Marked")
                            : StallyLocalization.string("Not marked")
                    )

                    if item.isArchived {
                        Text("Archived items are read-only. Move this item back to Library to change history.")
                            .font(StallyDesign.Typography.caption)
                            .foregroundStyle(StallyDesign.Palette.mutedInk)
                    }
                }

                Section {
                    Button(
                        selectedDateSummary.isMarkedToday
                            ? StallyLocalization.string("Remove Mark")
                            : StallyLocalization.string("Add Mark")
                    ) {
                        applyHistoryChange()
                    }
                    .disabled(item.isArchived)
                }
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

    var insightMetrics: [StallyMetricGrid.Metric] {
        [
            .init(
                title: StallyLocalization.string("Marks (30d)"),
                value: "\(markCount(inLast: 30))"
            ),
            .init(
                title: StallyLocalization.string("Marks (90d)"),
                value: "\(markCount(inLast: 90))"
            ),
            .init(
                title: StallyLocalization.string("Months Used"),
                value: "\(activeMonthCount)"
            ),
            .init(
                title: StallyLocalization.string("Days Since Last"),
                value: daysSinceLastMarkTitle
            )
        ]
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
        let didSucceed = appModel.performBooleanAction {
            try StallyAppActionService.setMarkState(
                context: context,
                item: item,
                on: selectedHistoryDate,
                shouldBeMarked: shouldBeMarked
            )
        }

        if didSucceed {
            isHistoryEditorPresented = false
        }
    }

    func markCount(
        inLast dayCount: Int
    ) -> Int {
        guard let windowStart = Calendar.current.date(
            byAdding: .day,
            value: -(dayCount - 1),
            to: Date.now
        ) else {
            return .zero
        }

        let startDay = Calendar.current.startOfDay(for: windowStart)
        let endDay = Calendar.current.startOfDay(for: Date.now)

        return item.marks.filter { mark in
            let day = Calendar.current.startOfDay(for: mark.day)
            return day >= startDay && day <= endDay
        }.count
    }

    var activeMonthCount: Int {
        Set(
            item.marks.map { mark in
                let components = Calendar.current.dateComponents(
                    [.year, .month],
                    from: mark.day
                )
                return "\(components.year ?? 0)-\(components.month ?? 0)"
            }
        ).count
    }

    var daysSinceLastMarkTitle: String {
        guard let lastMarkedAt = summary.lastMarkedAt else {
            return StallyLocalization.string("Never")
        }

        let dayCount = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: lastMarkedAt),
            to: Calendar.current.startOfDay(for: Date.now)
        ).day ?? .zero

        return "\(max(dayCount, 0))"
    }

    var adjustHistoryTip: (any Tip)? {
        guard item.isArchived == false else {
            return nil
        }

        return StallyTips.AdjustHistoryTip()
    }
}

@available(iOS 26.0, *)
#Preview(traits: .modifier(StallySampleData())) {
    @Previewable @Query var items: [Item]
    @Previewable @Namespace var namespace

    NavigationStack {
        if let item = ItemInsightsCalculator.activeItems(from: items).first {
            StallyItemDetailView(
                item: item,
                navigationNamespace: namespace
            )
        } else {
            EmptyView()
        }
    }
}
