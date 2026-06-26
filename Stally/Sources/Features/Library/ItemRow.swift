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

    @Environment(\.calendar)
    private var calendar

    let item: Item

    private var history: ItemHistorySnapshot {
        ItemOperations.historySnapshot(for: item, calendar: calendar)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
            HStack(alignment: .firstTextBaseline) {
                Text(item.name)
                    .mhRowTitle()

                Spacer()

                if ItemOperations.isMarked(item, on: .now, calendar: calendar) {
                    Text("Marked")
                        .mhBadge(
                            style: .accent,
                            accessibilityLabel: Text("Marked Today")
                        )
                }
            }

            HStack(spacing: Layout.metadataSpacing) {
                Text(item.category.title)

                if history.totalMarks > 0 {
                    Text("\(history.totalMarks, format: .number) marks")
                } else {
                    Text("Not yet")
                }
            }
            .mhRowOverline()

            if !item.note.isEmpty {
                Text(item.note)
                    .mhRowSupporting()
                    .lineLimit(Layout.noteLineLimit)
            }
        }
        .mhRow()
    }
}
