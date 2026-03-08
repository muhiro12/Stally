import MHUI
import StallyLibrary
import SwiftUI

struct StallyInsightsRankingSection: View {
    let itemsByID: [UUID: Item]
    let topRankings: [CollectionItemRanking]
    let quietRankings: [CollectionItemRanking]
    let usesCompactLayout: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rankings")
                .mhRowTitle()

            Text("A quick read on the items receiving the most attention and the ones drifting furthest into silence.")
                .mhRowSupporting()

            if usesCompactLayout {
                VStack(alignment: .leading, spacing: 12) {
                    rankingColumn(
                        title: "Top Items",
                        rankings: topRankings
                    )
                    rankingColumn(
                        title: "Quiet Items",
                        rankings: quietRankings
                    )
                }
            } else {
                HStack(alignment: .top, spacing: 12) {
                    rankingColumn(
                        title: "Top Items",
                        rankings: topRankings
                    )
                    rankingColumn(
                        title: "Quiet Items",
                        rankings: quietRankings
                    )
                }
            }
        }
        .mhSection(title: Text("Rankings"))
    }
}

private extension StallyInsightsRankingSection {
    func rankingColumn(
        title: String,
        rankings: [CollectionItemRanking]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .mhRowTitle()

            if rankings.isEmpty {
                Text("Nothing to rank yet.")
                    .mhRowSupporting()
            } else {
                ForEach(Array(rankings.prefix(3).enumerated()), id: \.element.itemID) { index, ranking in
                    row(
                        ordinal: index + 1,
                        ranking: ranking
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .mhSurfaceInset()
        .mhSurface(role: .muted)
    }

    func row(
        ordinal: Int,
        ranking: CollectionItemRanking
    ) -> some View {
        let itemName = itemsByID[ranking.itemID]?.name ?? "Unknown Item"

        return VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("\(ordinal). \(itemName)")
                    .font(.headline)

                Spacer(minLength: 12)

                Text("\(ranking.totalMarksInRange)")
                    .mhRowValue(colorRole: .accent)
            }

            Text(rankingSupportingText(for: ranking))
                .mhRowSupporting()
        }
    }

    func rankingSupportingText(
        for ranking: CollectionItemRanking
    ) -> String {
        if ranking.totalMarksInRange == .zero {
            if ranking.totalLifetimeMarks == .zero {
                return "Still untouched."
            }

            return "No marks in range, \(ranking.totalLifetimeMarks) lifetime."
        }

        return "\(ranking.activeDaysInRange) active days, \(ranking.totalLifetimeMarks) lifetime."
    }
}
