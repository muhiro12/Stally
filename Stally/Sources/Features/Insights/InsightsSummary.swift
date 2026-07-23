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

    var body: some View {
        let supporting = totalMarks == 0
            ? Text("No activity in this window yet.")
            : Text("The selected range shapes every reading below.")

        MHSummary(
            title: Text(rangeTitle),
            metadata: Text("Scope"),
            supporting: supporting
        ) {
            Text("\(totalMarks) marks")
                .mhBadge(style: .accent)
        }
    }
}
