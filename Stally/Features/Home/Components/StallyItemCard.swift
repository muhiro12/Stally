import MHDeepLinking
import MHUI
import StallyLibrary
import SwiftUI
import UIKit

struct StallyItemCard: View {
    @Environment(\.mhTheme)
    private var theme

    let item: Item
    let summary: ItemSummary
    let onOpen: () -> Void
    let onToggleTodayMark: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.group) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: theme.spacing.group) {
                    headerSection

                    Text(markSupportingText)
                        .mhRowSupporting()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(
                    RoundedRectangle(
                        cornerRadius: theme.radius.surface,
                        style: .continuous
                    )
                )
            }
            .buttonStyle(.plain)
            .contextMenu {
                if let itemLinkURL {
                    Button("Copy Item Link", systemImage: "link") {
                        UIPasteboard.general.url = itemLinkURL
                    }
                }
            }

            markButton
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .mhSurfaceInset()
        .mhSurface()
    }
}

private extension StallyItemCard {
    var headerSection: some View {
        HStack(alignment: .top, spacing: theme.spacing.group) {
            StallyItemArtworkView(
                photoData: item.photoData,
                category: item.category,
                width: 82,
                height: 98
            )

            VStack(alignment: .leading, spacing: theme.spacing.control) {
                VStack(alignment: .leading, spacing: theme.spacing.inline) {
                    Text(item.name)
                        .mhRowTitle()

                    Text(item.category.title)
                        .mhBadge(style: .accent)
                }

                statRow(
                    title: "Total marks",
                    value: "\(summary.totalMarks)",
                    colorRole: .accent
                )
                statRow(
                    title: "Last marked",
                    value: lastMarkedValue
                )
            }

            Spacer(minLength: .zero)
        }
    }

    var markButton: some View {
        Button(summary.isMarkedToday ? "Marked Today" : "Mark Today") {
            onToggleTodayMark()
        }
        .buttonStyle(
            .mhAction(summary.isMarkedToday ? .secondary : .primary)
        )
    }

    var lastMarkedValue: String {
        if let lastMarkedAt = summary.lastMarkedAt {
            return lastMarkedAt.formatted(date: .abbreviated, time: .omitted)
        }

        return "Not yet"
    }

    var markSupportingText: String {
        if summary.isMarkedToday {
            return "Tap again to remove today’s mark."
        }

        return "One mark is enough for today."
    }

    var itemLinkURL: URL? {
        StallyDeepLinking.codec().preferredURL(
            for: .item(item.id)
        )
    }

    func statRow(
        title: String,
        value: String,
        colorRole: MHColorRole = .secondaryText
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: theme.spacing.control) {
            Text(title)
                .mhRowSupporting()

            Spacer(minLength: theme.spacing.control)

            Text(value)
                .mhRowValue(colorRole: colorRole)
        }
    }
}
