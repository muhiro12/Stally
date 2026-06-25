//
//  CoverageRow.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import SwiftUI

struct CoverageRow: View {
    let title: LocalizedStringResource
    let coverage: CollectionCoverage

    var body: some View {
        LabeledContent {
            VStack(alignment: .trailing) {
                Text(coverage.fraction, format: .percent)

                Text("\(coverage.coveredCount, format: .number) of \(coverage.totalCount, format: .number)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } label: {
            Text(title)
        }
    }
}
