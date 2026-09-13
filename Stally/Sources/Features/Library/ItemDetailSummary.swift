//
//  ItemDetailSummary.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import MHUI
import SwiftUI

struct ItemDetailSummary: View {
    @Environment(\.mhTheme)
    private var theme

    let item: Item
    let isMarkedToday: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.inline) {
            Text(item.category.title)
                .mhTextStyle(.supporting, colorRole: .secondaryText)

            statusTitle
                .mhTextStyle(.summaryTitle)

            if !item.note.isEmpty {
                Text(item.note)
                    .mhTextStyle(.supporting, colorRole: .secondaryText)
            }
        }
        .padding(.vertical, theme.spacing.inline)
    }

    private var statusTitle: Text {
        if item.isArchived {
            return Text("Archived")
        }

        if isMarkedToday {
            return Text("Marked Today")
        }

        return Text("Not marked")
    }
}
