import MHUI
import StallyLibrary
import SwiftData
import SwiftUI

struct StallyItemDetailView: View {
    @Environment(\.mhTheme)
    private var theme
    @Environment(\.modelContext)
    private var context

    let item: Item
    let onEdit: (UUID) -> Void

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

    var heroSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.group) {
            HStack(alignment: .top, spacing: theme.spacing.group) {
                StallyItemArtworkView(
                    photoData: item.photoData,
                    category: item.category,
                    width: 132,
                    height: 164
                )

                VStack(alignment: .leading, spacing: theme.spacing.group) {
                    Text(item.name)
                        .font(.system(size: 28, weight: .semibold, design: .serif))

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

                Spacer(minLength: .zero)
            }

            if item.isArchived {
                Label("Archived items stay out of Home until you move them back.", systemImage: "archivebox.fill")
                    .mhRowSupporting()
            }
        }
        .mhSection(
            title: Text("Overview"),
            supporting: Text("Marks accumulate one day at a time."),
            accessory: {
                Text(item.category.title)
                    .mhBadge(style: .accent)
            }
        )
    }

    var actionSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            Button(action: toggleTodayMark) {
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

            Button(action: toggleArchiveState) {
                Label(
                    item.isArchived ? "Move Back to Home" : "Archive Item",
                    systemImage: item.isArchived ? "tray.and.arrow.up.fill" : "archivebox.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.mhSecondary)
        }
        .mhSection(
            title: Text("Actions"),
            supporting: Text("Mark the item for today or move it in and out of Archive without affecting past marks.")
        )
    }

    func noteSection(
        note: String
    ) -> some View {
        Text(note)
            .frame(maxWidth: .infinity, alignment: .leading)
            .mhSection(title: Text("Note"))
    }

    func toggleTodayMark() {
        do {
            _ = try MarkService.toggle(
                context: context,
                item: item
            )
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }

    func toggleArchiveState() {
        do {
            if item.isArchived {
                try ItemService.unarchive(
                    context: context,
                    item: item
                )
            } else {
                try ItemService.archive(
                    context: context,
                    item: item
                )
            }
        } catch {
            assertionFailure(error.localizedDescription)
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
                }
            )
        } else {
            EmptyView()
        }
    }
}
