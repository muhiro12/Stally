import MHUI
import SwiftUI

struct StallyInsightsView: View {
    var body: some View {
        ContentUnavailableView(
            "Insights",
            systemImage: "chart.xyaxis.line",
            description: Text(
                "Collection-level insight summaries are available here and will expand across the next set of changes."
            )
        )
        .mhEmptyStateLayout()
        .mhScreen(
            title: Text("Insights"),
            subtitle: Text("Read the collection as a pattern, not just a list.")
        )
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
    }
}

@available(iOS 18.0, *)
#Preview {
    NavigationStack {
        StallyInsightsView()
    }
}
