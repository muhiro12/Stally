//
//  InsightsSummary.swift
//  Stally
//
//  Created by Codex on 2026/07/18.
//

import MHUI
import SwiftUI

struct InsightsSummary: View {
    let totalMarks: Int
    let rangeTitle: LocalizedStringResource
    let choiceItemCount: Int
    let hasHistoryConflict: Bool

    var body: some View {
        MHSummary(
            title: Text(rangeTitle),
            metadata: Text("Scope"),
            supporting: supporting
        ) {
            Text("\(totalMarks) marks")
                .mhBadge(style: .accent)
        }
    }

    private var supporting: Text {
        if hasHistoryConflict {
            Text("Choice readings are incomplete. Enable Marks on items with existing history.")
        } else if choiceItemCount == 0 {
            Text("No items in this scope record Marks.")
        } else if totalMarks == 0 {
            Text("No activity in this window yet.")
        } else {
            Text("The selected range shapes every reading below.")
        }
    }
}
