//
//  InsightsHighlightsSection.swift
//  Stally
//
//  Created by Codex on 2026/07/23.
//

import MHUI
import SwiftUI

struct InsightsHighlightsSection: View {
    let snapshot: InsightsSnapshot

    var body: some View {
        MHFeatureGrid {
            InsightsActivityFeature(snapshot: snapshot)
        } supporting: {
            InsightsConsistencyFeature(snapshot: snapshot)
            InsightsCollectionHealthFeature(snapshot: snapshot)
        }
        .mhSection(
            "Overview",
            supporting: "Activity, consistency, and collection health at a glance."
        )
    }
}
