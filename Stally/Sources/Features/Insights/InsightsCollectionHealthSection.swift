//
//  InsightsCollectionHealthSection.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHUI
import SwiftUI

struct InsightsCollectionHealthSection: View {
    let snapshot: InsightsSnapshot

    var body: some View {
        Section {
            CoverageRow(title: "Note coverage", coverage: snapshot.noteCoverage)

            CoverageRow(title: "Photo coverage", coverage: snapshot.photoCoverage)
        } header: {
            MHSectionHeader("Collection Health")
        }
    }
}
