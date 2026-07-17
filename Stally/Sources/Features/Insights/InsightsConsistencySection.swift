//
//  InsightsConsistencySection.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHUI
import SwiftUI

struct InsightsConsistencySection: View {
    let snapshot: InsightsSnapshot

    var body: some View {
        MHGroupedRows {
            LabeledContent("Current Streak") {
                Text(snapshot.currentStreak, format: .number)
            }

            LabeledContent("Best Streak") {
                Text(snapshot.bestStreak, format: .number)
            }
        }
        .labeledContentStyle(.mhKeyValue)
        .mhSection("Consistency")
    }
}
