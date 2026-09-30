//
//  ItemRow.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import MHUI
import SwiftUI

struct ItemRow: View {
    private enum Layout {
        static let verticalSpacing: CGFloat = 6
        static let metadataSpacing: CGFloat = 8
        static let noteLineLimit = 2
    }

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize
    @Environment(\.locale)
    private var locale

    @Environment(\.stallyReadingDate)
    private var readingDate
    @Environment(\.timeZone)
    private var timeZone

    @Environment(Item.self)
    private var item

    private var name: some View {
        Text(item.name)
            .mhRowTitle()
            .fixedSize(horizontal: false, vertical: true)
    }

    var body: some View {
        let now = readingDate
        let today = LocalDay(containing: now, in: timeZone)
        let history = today.map { today in
            ItemOperations.historySnapshot(for: item, today: today)
        }

        VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
            title(isMarked: item.recordsMarks && today.map { ItemOperations.isMarked(item, on: $0) } == true)

            metadata(history: history)

            if let today {
                timeMetadata(snapshot: ItemTimeOperations.snapshot(for: item, today: today))
            }

            if !item.note.isEmpty {
                Text(item.note)
                    .mhRowSupporting()
                    .lineLimit(Layout.noteLineLimit)
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func title(isMarked: Bool) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
                name
                markedBadge(isMarked: isMarked)
            }
        } else {
            HStack(alignment: .firstTextBaseline) {
                name
                Spacer()
                markedBadge(isMarked: isMarked)
            }
        }
    }

    @ViewBuilder
    private func markedBadge(isMarked: Bool) -> some View {
        if isMarked {
            Text("Marked")
                .mhBadge(
                    style: .accent,
                    accessibilityLabel: Text("Marked Today")
                )
                .fixedSize()
        }
    }

    @ViewBuilder
    private func metadata(history: ItemHistorySnapshot?) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
                categoryAndCount(history: history)
            }
            .mhTextStyle(.metadata, colorRole: .secondaryText)
        } else {
            HStack(spacing: Layout.metadataSpacing) {
                categoryAndCount(history: history)
            }
            .mhTextStyle(.metadata, colorRole: .secondaryText)
        }
    }

    @ViewBuilder
    private func categoryAndCount(history: ItemHistorySnapshot?) -> some View {
        Text(item.category.title)
        if let history, item.recordsMarks {
            if history.totalMarks > 0 {
                Text("\(history.totalMarks) marks")
            } else {
                Text("Not yet")
            }
        }
    }

    @ViewBuilder
    private func timeMetadata(snapshot: ItemTimeSnapshot) -> some View {
        switch snapshot {
        case .unknown:
            EmptyView()
        case .invalidStart:
            Text("The stored start is invalid. Edit or clear it before saving.")
                .mhTextStyle(.metadata, colorRole: .secondaryText)
        case .notStarted(let start), .elapsed(let start, _, _):
            VStack(alignment: .leading, spacing: .zero) {
                Text("Start")
                ItemStartDateText(start: start)
                Text(ItemTimeOperations.elapsedText(for: snapshot, locale: locale))
            }
            .fixedSize(horizontal: false, vertical: true)
            .mhTextStyle(.metadata, colorRole: .secondaryText)
        }
    }
}
