//
//  CoverageRow.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHUI
import SwiftUI

struct CoverageRow: View {
    let title: LocalizedStringResource
    let coverage: CollectionCoverage

    var body: some View {
        LabeledContent {
            VStack(alignment: .trailing) {
                Text(coverage.fraction, format: .percent)

                Text("\(coverage.coveredCount, format: .number) of \(coverage.totalCount, format: .number)")
                    .mhTextStyle(.caption, colorRole: .secondaryText)
            }
        } label: {
            Text(title)
        }
    }
}
