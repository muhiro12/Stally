import StallyLibrary
import SwiftUI

struct StallyItemCard: View {
    let item: Item
    let summary: ItemSummary
    let onOpen: () -> Void
    let onToggleTodayMark: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                StallyItemArtworkView(
                    photoData: item.photoData,
                    category: item.category,
                    width: 82,
                    height: 98
                )

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.name)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text(item.category.title)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(StallyDesign.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(StallyDesign.accentMuted.opacity(0.35))
                            )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("\(summary.totalMarks) total marks", systemImage: "circle.hexagongrid.fill")
                            .font(.subheadline)
                            .foregroundStyle(.primary)

                        Label(lastMarkedText, systemImage: "calendar")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: .zero)
            }

            Button(action: onToggleTodayMark) {
                HStack {
                    Label(
                        summary.isMarkedToday ? "Marked Today" : "Mark Today",
                        systemImage: summary.isMarkedToday ? "checkmark.circle.fill" : "circle"
                    )
                    .font(.subheadline.weight(.semibold))

                    Spacer()

                    Text(summary.isMarkedToday ? "Tap to undo" : "One mark for today")
                        .font(.footnote)
                }
                .foregroundStyle(summary.isMarkedToday ? StallyDesign.accent : Color.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            summary.isMarkedToday
                                ? StallyDesign.accentMuted.opacity(0.42)
                                : StallyDesign.accent
                        )
                )
            }
            .buttonStyle(.plain)
        }
        .padding(22)
        .stallyCardStyle()
        .contentShape(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .onTapGesture(perform: onOpen)
    }
}

private extension StallyItemCard {
    var lastMarkedText: String {
        if let lastMarkedAt = summary.lastMarkedAt {
            return "Last marked \(lastMarkedAt.formatted(date: .abbreviated, time: .omitted))"
        }

        return "No marks yet"
    }
}
