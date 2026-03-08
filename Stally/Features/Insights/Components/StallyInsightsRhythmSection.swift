import MHUI
import StallyLibrary
import SwiftUI

struct StallyInsightsRhythmSection: View {
    let weekdaySummaries: [CollectionWeekdaySummary]
    let monthlySummaries: [CollectionMonthSummary]
    let usesCompactLayout: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rhythm")
                .mhRowTitle()

            Text("How activity is distributed across weekdays, and how it is rising or falling month to month.")
                .mhRowSupporting()

            weekdayLane
            monthlyLane
        }
        .mhSection(title: Text("Rhythm"))
    }
}

private extension StallyInsightsRhythmSection {
    var weekdayLane: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weekdays")
                .mhRowTitle()

            if weekdaySummaries.allSatisfy({ $0.markCount == .zero }) {
                Text("No weekday pattern yet.")
                    .mhRowSupporting()
            } else if usesCompactLayout {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(weekdaySummaries, id: \.weekday) { summary in
                        weekdayRow(summary)
                    }
                }
            } else {
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(weekdaySummaries, id: \.weekday) { summary in
                        VStack(spacing: 8) {
                            Capsule()
                                .fill(Color.accentColor.opacity(0.22))
                                .overlay(alignment: .bottom) {
                                    Capsule()
                                        .fill(Color.accentColor)
                                        .frame(height: weekdayBarHeight(for: summary))
                                }
                                .frame(width: 22, height: 92)

                            Text(summary.shortTitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .bottom)
                    }
                }
            }
        }
        .mhSurfaceInset()
        .mhSurface(role: .muted)
    }

    var monthlyLane: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Months")
                .mhRowTitle()

            if monthlySummaries.isEmpty {
                Text("No monthly trend available.")
                    .mhRowSupporting()
            } else {
                ForEach(monthlySummaries.suffix(4), id: \.monthStart) { summary in
                    monthlyRow(summary)
                }
            }
        }
        .mhSurfaceInset()
        .mhSurface(role: .muted)
    }

    func weekdayRow(
        _ summary: CollectionWeekdaySummary
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(summary.shortTitle)
                .font(.headline)
                .frame(width: 36, alignment: .leading)

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

            Text("\(summary.markCount)")
                .mhRowSupporting()
                .frame(width: 28, alignment: .trailing)
        }
    }

    func monthlyRow(
        _ summary: CollectionMonthSummary
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(summary.monthTitle)
                    .font(.headline)
                Text("\(summary.activeDays) active days")
                    .mhRowSupporting()
            }

            Spacer(minLength: 12)

            Text("\(summary.markCount)")
                .mhRowValue(colorRole: .accent)
        }
    }

    func weekdayBarHeight(
        for summary: CollectionWeekdaySummary
    ) -> CGFloat {
        let maximumMarks = max(weekdaySummaries.map(\.markCount).max() ?? 0, 1)
        let normalized = CGFloat(summary.markCount) / CGFloat(maximumMarks)

        return max(10, normalized * 72)
    }
}
