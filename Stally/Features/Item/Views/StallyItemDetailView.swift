import StallyLibrary
import SwiftData
import SwiftUI

struct StallyItemDetailView: View {
    @Environment(\.modelContext)
    private var context

    let item: Item
    let onEdit: (UUID) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                heroSection
                actionSection

                if let note = item.note {
                    noteSection(note: note)
                }

                StallyHistorySection(
                    months: MarkHistoryCalculator.months(for: item)
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    onEdit(item.id)
                }
            }
        }
        .stallyScreenBackground()
    }
}

private extension StallyItemDetailView {
    var summary: ItemSummary {
        ItemInsightsCalculator.summary(for: item)
    }

    var heroSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 18) {
                StallyItemArtworkView(
                    photoData: item.photoData,
                    category: item.category,
                    width: 132,
                    height: 164
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text(item.name)
                        .font(.system(size: 28, weight: .semibold, design: .serif))

                    Text(item.category.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(StallyDesign.accent)

                    detailStat(
                        title: "Total marks",
                        value: "\(summary.totalMarks)"
                    )
                    detailStat(
                        title: "Last marked",
                        value: summary.lastMarkedAt?.formatted(date: .abbreviated, time: .omitted)
                            ?? "Not yet"
                    )
                }

                Spacer(minLength: .zero)
            }

            if item.isArchived {
                Label("Archived items stay out of Home until you move them back.", systemImage: "archivebox.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .stallyCardStyle(cornerRadius: 32)
    }

    var actionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: toggleTodayMark) {
                Label(
                    summary.isMarkedToday ? "Undo Today’s Mark" : "Mark Today",
                    systemImage: summary.isMarkedToday ? "checkmark.circle.fill" : "circle.fill"
                )
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(StallyDesign.accent)
            .disabled(item.isArchived)

            Button(action: toggleArchiveState) {
                Label(
                    item.isArchived ? "Move Back to Home" : "Archive Item",
                    systemImage: item.isArchived ? "tray.and.arrow.up.fill" : "archivebox.fill"
                )
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.bordered)
        }
        .padding(24)
        .stallyCardStyle(cornerRadius: 32)
    }

    func noteSection(
        note: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Note")
                .font(.headline)

            Text(note)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .stallyCardStyle(cornerRadius: 28)
    }

    func detailStat(
        title: String,
        value: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.body.weight(.semibold))
        }
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
