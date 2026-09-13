import SwiftUI

struct ItemStartDateText: View {
    @Environment(\.locale)
    private var locale

    let start: ItemStart

    var body: some View {
        let style = Date.FormatStyle(
            date: .omitted,
            time: .omitted,
            locale: locale,
            calendar: .init(identifier: .gregorian),
            timeZone: .gmt
        )
        if let date = start.earliestDay.date(in: .gmt) {
            switch start.precision {
            case .year:
                Text(date, format: style.year())
            case .month:
                Text(date, format: style.year().month(.wide))
            case .day:
                Text(date, format: style.year().month(.wide).day())
            }
        } else {
            Text(start.rawValue)
        }
    }
}
