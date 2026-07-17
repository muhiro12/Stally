//
//  InsightsScopeSection.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHUI
import SwiftUI

struct InsightsScopeSection: View {
    @Binding var selectedRange: InsightsRange
    @Binding var includesArchivedItems: Bool

    var body: some View {
        Section {
            Picker("Default range", selection: $selectedRange) {
                ForEach(InsightsRange.allCases) { range in
                    Text(range.title)
                        .tag(range)
                }
            }
            .mhRow()

            Toggle("Include archived items", isOn: $includesArchivedItems)
                .mhRow()
        } header: {
            MHSectionHeader("Scope")
        }
    }
}
