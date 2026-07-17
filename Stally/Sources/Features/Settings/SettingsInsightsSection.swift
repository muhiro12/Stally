//
//  SettingsInsightsSection.swift
//  Stally
//
//  Created by Codex on 2026/07/13.
//

import MHUI
import SwiftUI

struct SettingsInsightsSection: View {
    @Binding var defaultRange: InsightsRange
    @Binding var includesArchivedItems: Bool

    var body: some View {
        Section {
            Picker("Default range", selection: $defaultRange) {
                ForEach(InsightsRange.allCases) { range in
                    Text(range.title)
                        .tag(range)
                }
            }
            .mhRow()

            Toggle("Include archived items", isOn: $includesArchivedItems)
                .mhRow()
        } header: {
            MHSectionHeader("Insights")
        }
    }
}
