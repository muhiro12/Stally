import StallyLibrary
import SwiftUI

struct StallyHistorySection: View {
    let months: [MarkHistoryMonth]

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 8),
        count: 7
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Quiet History")
                .font(.title3.weight(.semibold))

            Text("One filled day means you chose this item on that date.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(months) { month in
                VStack(alignment: .leading, spacing: 14) {
                    Text(month.monthStart.formatted(.dateTime.year().month(.wide)))
                        .font(.headline)

                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(weekdaySymbols, id: \.self) { symbol in
                            Text(symbol)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
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
                .padding(18)
                .stallyCardStyle(cornerRadius: 24)
            }
        }
    }
}

private extension StallyHistorySection {
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
            return StallyDesign.accent
        }

        if cell.isInDisplayedMonth {
            return Color.white.opacity(0.5)
        }

        return Color.white.opacity(0.18)
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
