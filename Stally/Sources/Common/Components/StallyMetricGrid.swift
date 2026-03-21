import SwiftUI

struct StallyMetricGrid: View {
    struct Metric: Hashable, Identifiable {
        let title: String
        let value: String

        var id: String {
            title
        }
    }

    let metrics: [Metric]
    let usesCompactLayout: Bool

    var body: some View {
        if usesCompactLayout {
            LazyVGrid(
                columns: columns,
                alignment: .leading,
                spacing: 12
            ) {
                ForEach(metrics) { metric in
                    metricView(metric)
                }
            }
        } else {
            HStack(spacing: 12) {
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
                spacing: 12,
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
                .font(.caption.weight(.semibold))
                .foregroundStyle(StallyDesign.Palette.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
            Text(metric.value)
                .font(StallyDesign.Typography.metric)
                .monospacedDigit()
                .foregroundStyle(StallyDesign.Palette.ink)
                .contentTransition(.symbolEffect)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .stallyPanel(.elevated, padding: 14)
    }
}
