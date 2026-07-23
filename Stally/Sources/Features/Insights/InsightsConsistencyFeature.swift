//
//  InsightsConsistencyFeature.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHUI
import SwiftUI

struct InsightsConsistencyFeature: View {
    let snapshot: InsightsSnapshot

    var body: some View {
        InsightsFeatureTile(
            metadata: "Consistency",
            value: Text(snapshot.currentStreak, format: .number),
            title: "Current Streak",
            surfaceRole: .muted
        ) {
            LabeledContent("Best Streak") {
                Text(snapshot.bestStreak, format: .number)
            }
            .labeledContentStyle(.mhKeyValue)
        }
    }
}
