import MHUI
import StallyLibrary
import SwiftUI

struct StallyInsightsCategorySection: View {
    let summaries: [CollectionCategorySummary]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .mhRowTitle()

            Text("Which categories are carrying the most marks in the selected range.")
                .mhRowSupporting()

            if summaries.isEmpty {
                Text("No category activity in this window yet.")
                    .mhRowSupporting()
            } else {
                ForEach(summaries.prefix(4), id: \.category) { summary in
                    row(for: summary)
                }
            }
        }
        .mhSection(title: Text("Categories"))
    }
}

private extension StallyInsightsCategorySection {
    func row(
        for summary: CollectionCategorySummary
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Label(summary.category.title, systemImage: summary.category.symbolName)
                    .font(.headline)

                Spacer(minLength: 12)

                Text("\(summary.totalMarks)")
                    .mhRowValue(colorRole: .accent)
            }

            Capsule()
                .fill(Color.accentColor.opacity(0.2))
                .overlay(alignment: .leading) {
                    GeometryReader { proxy in
                        Capsule()
                            .fill(Color.accentColor)
                            .frame(width: proxy.size.width * summary.shareOfMarks)
                    }
                }
                .frame(height: 8)

            Text(
                "\(summary.uniqueItems) items, \(summary.shareOfMarks.formatted(.percent.precision(.fractionLength(0)))) of marks"
            )
            .mhRowSupporting()
        }
        .mhSurfaceInset()
        .mhSurface(role: .muted)
    }
}
