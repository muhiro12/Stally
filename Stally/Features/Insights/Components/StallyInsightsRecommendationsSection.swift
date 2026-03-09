import MHUI
import StallyLibrary
import SwiftUI

struct StallyInsightsRecommendationsSection: View {
    let recommendations: [CollectionRecommendation]
    let itemsByID: [UUID: Item]
    let onOpenItem: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Next Moves")
                .mhRowTitle()

            Text("Suggested follow-ups based on the current range and scope.")
                .mhRowSupporting()

            if recommendations.isEmpty {
                Text("No follow-up suggestions right now.")
                    .mhRowSupporting()
            } else {
                ForEach(recommendations, id: \.title) { recommendation in
                    recommendationCard(recommendation)
                }
            }
        }
        .mhSection(title: Text("Recommendations"))
    }
}

private extension StallyInsightsRecommendationsSection {
    func recommendationCard(
        _ recommendation: CollectionRecommendation
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(recommendation.title)
                .mhRowTitle()

            Text(recommendation.message)
                .mhRowSupporting()

            if !recommendation.itemIDs.isEmpty {
                Text(suggestedItemsTitle(for: recommendation))
                    .mhRowSupporting()

                Button("Open Suggested Item") {
                    if let itemID = recommendation.itemIDs.first {
                        onOpenItem(itemID)
                    }
                }
                .buttonStyle(.mhSecondary)
            }
        }
        .mhSurfaceInset()
        .mhSurface(role: .muted)
    }

    func suggestedItemsTitle(
        for recommendation: CollectionRecommendation
    ) -> String {
        let titles = recommendation.itemIDs
            .compactMap { itemID in
                itemsByID[itemID]?.name
            }
            .prefix(3)
            .joined(separator: ", ")

        return titles.isEmpty
            ? StallyLocalization.string("Suggested items are unavailable.")
            : titles
    }
}
