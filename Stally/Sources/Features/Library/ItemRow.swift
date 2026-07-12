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

    @Environment(\.timeZone)
    private var timeZone

    let item: Item

    var body: some View {
        let now = Date()
        let today = LocalDay(containing: now, in: timeZone)
        let history = today.map { today in
            ItemOperations.historySnapshot(for: item, today: today)
        }

        VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
            HStack(alignment: .firstTextBaseline) {
                Text(item.name)
                    .mhRowTitle()

                Spacer()

                if let today,
                   ItemOperations.isMarked(item, on: today) {
                    Text("Marked")
                        .mhBadge(
                            style: .accent,
                            accessibilityLabel: Text("Marked Today")
                        )
                }
            }

            HStack(spacing: Layout.metadataSpacing) {
                Text(item.category.title)

                if let history {
                    if history.totalMarks > 0 {
                        Text("\(history.totalMarks) marks")
                    } else {
                        Text("Not yet")
                    }
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
