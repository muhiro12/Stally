import MHUI
import StallyLibrary
import SwiftUI

struct StallyHistorySection: View {
    @Environment(\.stallyMHUIThemeMetrics)
    private var theme

    let months: [MarkHistoryMonth]

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.group) {
            ForEach(months) { month in
                VStack(alignment: .leading, spacing: theme.spacing.control) {
                    Text(month.monthStart.formatted(.dateTime.year().month(.wide)))
                        .mhRowTitle()

                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(weekdaySymbols, id: \.self) { symbol in
                            Text(symbol)
                                .mhRowOverline()
                                .frame(maxWidth: .infinity)
                        }

                        ForEach(month.cells) { cell in
                            Text("\(cell.dayNumber)")
                                .font(.caption2.weight(.medium))
                                .frame(maxWidth: .infinity, minHeight: 28)
                                .foregroundStyle(foregroundStyle(for: cell))
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(backgroundColor(for: cell))
                                )
                        }
                    }
                }
                .mhSurfaceInset()
                .mhSurface(role: .muted)
            }
        }
    }
}

private extension StallyHistorySection {
    var columns: [GridItem] {
        Array(
            repeating: .init(
                .flexible(),
                spacing: theme.spacing.inline * 2
            ),
            count: 7
        )
    }

    var weekdaySymbols: [String] {
        let calendar: Calendar = .current
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let firstWeekdayIndex = max(calendar.firstWeekday - 1, 0)
        return Array(symbols[firstWeekdayIndex...] + symbols[..<firstWeekdayIndex])
    }

    func backgroundColor(
        for cell: MarkHistoryDayCell
    ) -> Color {
        guard cell.isInDisplayedMonth else {
            return Color.secondary.opacity(0.08)
        }

        if cell.isMarked {
            return StallyDesign.tint
        }

        return Color.secondary.opacity(0.14)
    }

    func foregroundStyle(
        for cell: MarkHistoryDayCell
    ) -> Color {
        if cell.isMarked {
            return .white
        }

        return cell.isInDisplayedMonth ? .primary : .secondary
    }
}
