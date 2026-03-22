import MHUI
import SwiftUI

struct StallyMetricGrid: View {
    struct Metric: Hashable, Identifiable {
        let title: String
        let value: String

        var id: String {
            title
        }
    }

    @Environment(\.mhTheme)
    private var theme

    let metrics: [Metric]
    let usesCompactLayout: Bool

    var body: some View {
        if usesCompactLayout {
            LazyVGrid(
                columns: columns,
                alignment: .leading,
                spacing: theme.spacing.control
            ) {
                ForEach(metrics) { metric in
                    metricView(metric)
                }
            }
        } else {
            HStack(spacing: theme.spacing.group) {
                ForEach(metrics) { metric in
                    metricView(metric)
                }
            }
        }
    }
}

private extension StallyMetricGrid {
    var columns: [GridItem] {
        Array(
            repeating: GridItem(
                .flexible(minimum: 0, maximum: .infinity),
                spacing: theme.spacing.group,
                alignment: .leading
            ),
            count: 2
        )
    }

    func metricView(
        _ metric: Metric
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(metric.title)
                .mhRowSupporting()
                .fixedSize(horizontal: false, vertical: true)
            Text(metric.value)
                .mhRowValue(colorRole: .accent)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
