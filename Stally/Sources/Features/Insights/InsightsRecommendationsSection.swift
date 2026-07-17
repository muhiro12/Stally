//
//  InsightsRecommendationsSection.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHUI
import SwiftUI

struct InsightsRecommendationsSection: View {
    let recommendations: [InsightRecommendation]

    var body: some View {
        MHGroupedRows {
            if recommendations.isEmpty {
                Text("No follow-up suggestions right now.")
                    .mhRowSupporting()
            } else {
                ForEach(recommendations, id: \.kind) { recommendation in
                    VStack(alignment: .leading) {
                        Text(recommendation.title)
                            .mhRowTitle()

                        Text(recommendation.summary)
                            .mhRowSupporting()
                    }
                }
            }
        }
        .mhSection("Next Moves")
    }
}
