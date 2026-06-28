//
//  InsightsList.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHPlatform
import SwiftUI

struct InsightsList: View {
    @AppStorage(\.isSubscribeOn)
    private var isSubscribeOn

    let snapshot: InsightsSnapshot
    @Binding var selectedRange: InsightsRange
    @Binding var includesArchivedItems: Bool

    var body: some View {
        List {
            InsightsScopeSection(
                selectedRange: $selectedRange,
                includesArchivedItems: $includesArchivedItems
            )

            InsightsActivitySection(snapshot: snapshot)

            InsightsConsistencySection(snapshot: snapshot)

            InsightsCategoryShareSection(categoryShares: snapshot.categoryShares)

            InsightsRankingSection(
                title: "Top Items",
                emptyMessage: "No activity in this window yet.",
                summaries: snapshot.topItems
            )

            InsightsRankingSection(
                title: "Quiet Items",
                emptyMessage: "No quiet items in this window yet.",
                summaries: snapshot.quietItems
            )

            InsightsCollectionHealthSection(snapshot: snapshot)

            if !isSubscribeOn {
                StallyAdvertisementSection(size: .medium)
            }

            InsightsRecommendationsSection(recommendations: snapshot.recommendations)
        }
        .stallyListChrome()
    }
}
