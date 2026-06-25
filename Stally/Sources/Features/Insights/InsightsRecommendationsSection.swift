//
//  InsightsRecommendationsSection.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import SwiftUI

struct InsightsRecommendationsSection: View {
    let recommendations: [InsightRecommendation]

    var body: some View {
        Section("Next Moves") {
            if recommendations.isEmpty {
                Text("No follow-up suggestions right now.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(recommendations, id: \.kind) { recommendation in
                    VStack(alignment: .leading) {
                        Text(recommendation.title)
                            .font(.headline)

                        Text(recommendation.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
