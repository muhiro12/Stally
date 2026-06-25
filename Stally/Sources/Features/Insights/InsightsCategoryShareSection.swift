//
//  InsightsCategoryShareSection.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import SwiftUI

struct InsightsCategoryShareSection: View {
    let categoryShares: [CategoryShare]

    var body: some View {
        Section("Categories") {
            if categoryShares.isEmpty {
                Text("No category activity in this window yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(categoryShares, id: \.category) { categoryShare in
                    LabeledContent {
                        VStack(alignment: .trailing) {
                            Text(categoryShare.markCount, format: .number)

                            Text(categoryShare.fraction, format: .percent)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } label: {
                        Text(categoryShare.category.title)
                    }
                }
            }
        }
    }
}
