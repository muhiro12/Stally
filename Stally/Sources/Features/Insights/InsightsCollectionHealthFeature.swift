//
//  InsightsCollectionHealthFeature.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHUI
import SwiftUI

struct InsightsCollectionHealthFeature: View {
    let snapshot: InsightsSnapshot

    var body: some View {
        InsightsFeatureTile(
            metadata: "Collection Health",
            value: Text(snapshot.noteCoverage.fraction, format: .percent),
            title: "Note coverage",
            surfaceRole: .muted
        ) {
            CoverageRow(title: "Photo coverage", coverage: snapshot.photoCoverage)
                .labeledContentStyle(.mhKeyValue)
        }
    }
}
