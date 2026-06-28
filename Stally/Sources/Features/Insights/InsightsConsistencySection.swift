//
//  InsightsConsistencySection.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import SwiftUI

struct InsightsConsistencySection: View {
    let snapshot: InsightsSnapshot

    var body: some View {
        Section("Consistency") {
            LabeledContent("Current Streak") {
                Text(snapshot.currentStreak, format: .number)
            }

            LabeledContent("Best Streak") {
                Text(snapshot.bestStreak, format: .number)
            }
        }
    }
}
