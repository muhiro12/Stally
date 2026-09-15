//
//  InsightsSummary.swift
//  Stally
//
//  Created by Codex on 2026/07/18.
//

import MHUI
import SwiftUI

struct InsightsSummary: View {
    @Environment(\.mhTheme)
    private var theme

    let totalMarks: Int
    let rangeTitle: LocalizedStringResource
    let includesArchivedItems: Bool
    let choiceItemCount: Int
    let hasHistoryConflict: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.inline) {
            Text(rangeTitle)
                .mhTextStyle(.bodyStrong)

            Text("\(totalMarks) marks")
                .mhTextStyle(.supporting, colorRole: .secondaryText)

            if includesArchivedItems {
                Text("Library and Archive")
                    .mhTextStyle(.supporting, colorRole: .secondaryText)
            }

            if let supporting {
                supporting
                    .mhTextStyle(.supporting, colorRole: .secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var supporting: Text? {
        if hasHistoryConflict {
            Text("Choice readings are incomplete. Enable Marks on items with existing history.")
        } else if choiceItemCount == 0 {
            Text("No items in this scope record Marks.")
        } else if totalMarks == 0 {
            Text("No activity in this window yet.")
        } else {
            nil
        }
    }
}
