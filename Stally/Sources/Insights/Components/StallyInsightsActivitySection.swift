import MHUI
import StallyLibrary
import SwiftUI

struct StallyInsightsActivitySection: View {
    @Environment(\.stallyMHUIThemeMetrics)
    private var theme

    let days: [CollectionActivityDay]
    let summary: CollectionActivitySummary
    let usesCompactLayout: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            Text("Activity")
                .mhRowTitle()

            Text("Daily marks across the selected range, with emphasis on the busiest pockets of usage.")
                .mhRowSupporting()

            if days.isEmpty {
                Text("No activity in this window yet.")
                    .mhRowSupporting()
            } else {
                chart

                StallyMetricGrid(
                    metrics: metrics,
                    usesCompactLayout: usesCompactLayout
                )
            }
        }
        .mhSection(title: Text("Activity"))
    }
}

private extension StallyInsightsActivitySection {
    var metrics: [StallyMetricGrid.Metric] {
        [
            .init(
                title: StallyLocalization.string("Unique Items"),
                value: "\(summary.uniqueMarkedItems)"
            ),
            .init(
                title: StallyLocalization.string("Categories"),
                value: "\(summary.uniqueMarkedCategories)"
            ),
            .init(
                title: StallyLocalization.string("Avg / Active Day"),
                value: summary.averageMarksPerActiveDay.formatted(
                    .number.precision(.fractionLength(1))
                )
            ),
            .init(
                title: StallyLocalization.string("Busiest Day"),
                value: busiestDayValue
            )
        ]
    }

    var chart: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(days, id: \.date) { day in
                    VStack(spacing: 6) {
                        Capsule()
                            .fill(
                                day.isActive
                                    ? AnyShapeStyle(Color.accentColor)
                                    : AnyShapeStyle(Color.secondary.opacity(0.18))
                            )
                            .frame(width: 8, height: barHeight(for: day))

                        if shouldShowLabel(for: day) {
                            Text(day.date, format: .dateTime.month(.abbreviated).day())
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .rotationEffect(.degrees(-45))
                                .frame(height: 32)
                        } else {
                            Color.clear
                                .frame(height: 32)
                        }
                    }
                    .frame(width: 14, alignment: .bottom)
                }
            }
            .frame(height: 160, alignment: .bottomLeading)
            .padding(.vertical, 4)
        }
        .mhSurfaceInset()
        .mhSurface(role: .muted)
    }

    var busiestDayValue: String {
        guard let busiestDay = summary.busiestDay else {
            return StallyLocalization.string("None")
        }

        return StallyLocalization.format(
            "%1$lld on %2$@",
            busiestDay.markCount,
            busiestDay.date.formatted(date: .abbreviated, time: .omitted)
        )
    }

    func barHeight(
        for day: CollectionActivityDay
    ) -> CGFloat {
        let maximumMarks = max(days.map(\.markCount).max() ?? 0, 1)
        let normalized = CGFloat(day.markCount) / CGFloat(maximumMarks)

        return max(12, normalized * 96)
    }

    func shouldShowLabel(
        for day: CollectionActivityDay
    ) -> Bool {
        guard let index = days.firstIndex(where: { $0.date == day.date }) else {
            return false
        }

        if index == .zero || index == days.count - 1 {
            return true
        }

        let divisor = max(days.count / 4, 1)
        return index.isMultiple(of: divisor)
    }
}
