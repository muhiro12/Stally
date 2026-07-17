//
//  InsightsReportSection.swift
//  Stally
//
//  Created by Codex on 2026/07/13.
//

import SwiftUI

struct InsightsReportSection: View {
    let report: String

    var body: some View {
        Section {
            ShareLink(item: report) {
                Label("Share Report", systemImage: "square.and.arrow.up")
            }
        } header: {
            StallySectionHeader("Report")
        }
    }
}
