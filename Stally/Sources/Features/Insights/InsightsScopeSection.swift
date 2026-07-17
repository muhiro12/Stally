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
        MHGroupedRows {
            LabeledContent("Default range") {
                Picker("Default range", selection: $selectedRange) {
                    ForEach(InsightsRange.allCases) { range in
                        Text(range.title)
                            .tag(range)
                    }
                }
                .labelsHidden()
            }

            Toggle("Include archived items", isOn: $includesArchivedItems)
        }
        .labeledContentStyle(.mhKeyValue)
        .mhSection("Scope")
    }
}
