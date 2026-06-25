//
//  ItemRow.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import SwiftUI

struct ItemRow: View {
    private enum Layout {
        static let verticalSpacing: CGFloat = 6
        static let metadataSpacing: CGFloat = 8
        static let noteLineLimit = 2
        static let verticalPadding: CGFloat = 4
    }

    @Environment(\.calendar)
    private var calendar

    let item: Item

    private var history: ItemHistorySnapshot {
        item.historySnapshot(calendar: calendar)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
            HStack(alignment: .firstTextBaseline) {
                Text(item.name)
                    .font(.headline)

                Spacer()

                if item.isMarked(on: .now, calendar: calendar) {
                    Label("Marked Today", systemImage: "checkmark.circle.fill")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.tint)
                        .accessibilityLabel("Marked Today")
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
            .font(.subheadline)
            .foregroundStyle(.secondary)

            if !item.note.isEmpty {
                Text(item.note)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(Layout.noteLineLimit)
            }
        }
        .padding(.vertical, Layout.verticalPadding)
    }
}
