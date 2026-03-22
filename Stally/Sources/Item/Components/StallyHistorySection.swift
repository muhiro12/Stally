import StallyLibrary
import SwiftUI

struct StallyHistorySection: View {
    let months: [MarkHistoryMonth]

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: StallyDesign.Layout.blockSpacing
        ) {
            ForEach(months) { month in
                VStack(
                    alignment: .leading,
                    spacing: StallyDesign.Layout.compactSpacing
                ) {
                    Text(month.monthStart.formatted(.dateTime.year().month(.wide)))
                        .stallyCardTitle()

                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(weekdaySymbols, id: \.self) { symbol in
                            Text(symbol)
                                .stallyOverlineText()
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
                .stallyPanel(.quiet, padding: 16)
            }
        }
    }
}

private extension StallyHistorySection {
    var columns: [GridItem] {
        Array(
            repeating: .init(
                .flexible(),
                spacing: StallyDesign.Layout.compactSpacing
            ),
            count: 7
        )
    }

    var weekdaySymbols: [String] {
        let calendar: Calendar = .current
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let firstWeekdayIndex = calendar.firstWeekday - 1

        return Array(symbols[firstWeekdayIndex...]) + Array(symbols[..<firstWeekdayIndex])
    }

    func backgroundColor(
        for cell: MarkHistoryDayCell
    ) -> Color {
        if cell.isMarked {
            return StallyDesign.tint
        }

        if cell.isInDisplayedMonth {
            return Color.secondary.opacity(0.14)
        }

        return Color.secondary.opacity(0.08)
    }

    func foregroundStyle(
        for cell: MarkHistoryDayCell
    ) -> Color {
        if cell.isMarked {
            return .white
        }

        if cell.isInDisplayedMonth {
            return StallyDesign.Palette.ink
        }

        return StallyDesign.Palette.mutedInk
    }
}
