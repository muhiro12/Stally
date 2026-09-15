//
//  InsightsScopeMenu.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import SwiftUI

struct InsightsScopeMenu: View {
    @Binding var selectedRange: InsightsRange
    @Binding var includesArchivedItems: Bool

    var body: some View {
        Menu {
            Picker("Reading Range", selection: $selectedRange) {
                ForEach(InsightsRange.allCases) { range in
                    Text(range.title)
                        .tag(range)
                }
            }

            Toggle("Include archived items", isOn: $includesArchivedItems)
        } label: {
            Label("Scope", systemImage: "line.3.horizontal.decrease")
        }
        .stallyToolbarActionStyle()
    }
}
