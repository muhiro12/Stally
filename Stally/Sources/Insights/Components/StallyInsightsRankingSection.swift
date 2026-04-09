import MHUI
import StallyLibrary
import SwiftUI

struct StallyInsightsRankingSection: View {
    @Environment(\.mhDesignMetrics)
    private var theme

    let itemsByID: [UUID: Item]
    let topRankings: [CollectionItemRanking]
    let quietRankings: [CollectionItemRanking]
    let usesCompactLayout: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            Text("Rankings")
                .mhRowTitle()

            Text("A quick read on the items receiving the most attention and the ones drifting furthest into silence.")
                .mhRowSupporting()

            if usesCompactLayout {
                VStack(alignment: .leading, spacing: theme.spacing.control) {
                    rankingColumn(
                        title: StallyLocalization.string("Top Items"),
                        rankings: topRankings
                    )
                    rankingColumn(
                        title: StallyLocalization.string("Quiet Items"),
                        rankings: quietRankings
                    )
                }
            } else {
                HStack(alignment: .top, spacing: theme.spacing.control) {
                    rankingColumn(
                        title: StallyLocalization.string("Top Items"),
                        rankings: topRankings
                    )
                    rankingColumn(
                        title: StallyLocalization.string("Quiet Items"),
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
        VStack(alignment: .leading, spacing: theme.spacing.inline) {
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
        let itemName = itemsByID[ranking.itemID]?.name
            ?? StallyLocalization.string("Unknown Item")

        return VStack(alignment: .leading, spacing: theme.spacing.inline) {
            HStack(alignment: .firstTextBaseline, spacing: theme.spacing.control) {
                Text("\(ordinal). \(itemName)")
                    .font(.headline)

                Spacer(minLength: theme.spacing.control)

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
                return StallyLocalization.string("Still untouched.")
            }

            return StallyLocalization.format(
                "No marks in range, %lld lifetime.",
                ranking.totalLifetimeMarks
            )
        }

        return StallyLocalization.format(
            "%1$lld active days, %2$lld lifetime.",
            ranking.activeDaysInRange,
            ranking.totalLifetimeMarks
        )
    }
}
