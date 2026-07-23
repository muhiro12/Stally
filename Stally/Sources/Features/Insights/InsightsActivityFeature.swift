//
//  InsightsActivityFeature.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHUI
import SwiftUI

struct InsightsActivityFeature: View {
    @Environment(\.mhTheme)
    private var theme

    let snapshot: InsightsSnapshot

    var body: some View {
        InsightsFeatureTile(
            metadata: "Activity",
            value: Text(snapshot.activeDays, format: .number),
            title: "Active Days",
            surfaceRole: .elevated
        ) {
            VStack(spacing: theme.spacing.inline) {
                LabeledContent("Unique Items") {
                    Text(snapshot.uniqueMarkedItems, format: .number)
                }

                Divider()

                LabeledContent("Unique Categories") {
                    Text(snapshot.uniqueMarkedCategories, format: .number)
                }
            }
            .labeledContentStyle(.mhKeyValue)
        }
    }
}
