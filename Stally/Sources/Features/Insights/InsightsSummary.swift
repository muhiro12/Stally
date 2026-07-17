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
        MHSummary(
            title: Text(totalMarks, format: .number),
            metadata: Text("Marks")
        ) {
            Text(rangeTitle)
                .mhBadge(style: .neutral)
        }
    }
}
