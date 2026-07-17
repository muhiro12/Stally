//
//  InsightsCategoryShareSection.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHUI
import SwiftUI

struct InsightsCategoryShareSection: View {
    let categoryShares: [CategoryShare]

    var body: some View {
        Section {
            if categoryShares.isEmpty {
                Text("No category activity in this window yet.")
                    .mhRowSupporting()
            } else {
                ForEach(categoryShares, id: \.category) { categoryShare in
                    LabeledContent {
                        VStack(alignment: .trailing) {
                            Text(categoryShare.markCount, format: .number)

                            Text(categoryShare.fraction, format: .percent)
                                .mhTextStyle(.caption, colorRole: .secondaryText)
                        }
                    } label: {
                        Text(categoryShare.category.title)
                    }
                }
            }
        } header: {
            StallySectionHeader("Categories")
        }
    }
}
