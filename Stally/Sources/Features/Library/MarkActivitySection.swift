import MHUI
import StallyLibrary
import SwiftUI

struct MarkActivitySection: View {
    private struct Day: Identifiable {
        let date: Date
        let key: String
        var id: String { key }
    }

    private static let daysPerWeek = 7
    private static let weekCount = 4
    private static let cellInset: CGFloat = 2
    private static let cornerRadius: CGFloat = 6
    private static let dotSize: CGFloat = 4
    private static let emptyOpacity = 0.08
    private static let opacityStep = 0.2
    private static let maximumIntensity = 3
    @Environment(\.locale)
    private var locale
    @Environment(\.markToday)
    private var today
    let items: [Item]
    let selectDay: (String) -> Void

    private var recentDays: [Day] {
        let formatter = RecordDateDraft.formatter("yyyy-MM-dd")
        var calendar = RecordDateDraft.calendar
        calendar.locale = locale
        guard let currentDate = formatter.date(from: today),
              let week = calendar.dateInterval(of: .weekOfYear, for: currentDate),
              let start = calendar.date(byAdding: .weekOfYear, value: 1 - Self.weekCount, to: week.start)
        else {
            return []
        }
        return (0 ..< Self.daysPerWeek * Self.weekCount).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else {
                return nil
            }
            return Day(date: date, key: formatter.string(from: date))
        }
    }

    var body: some View {
        let days = recentDays
        if let first = days.first, let currentDay = days.last(where: { $0.key == today }) {
            let counts = totals(in: first.key...today)
            Section {
                VStack(alignment: .leading) {
                    Text(first.date..<currentDay.date, format: .interval.month(.abbreviated).day())
                        .mhRowSupporting()
                    grid(days: days, counts: counts)
                }
                .environment(\.timeZone, .gmt)
            } header: {
                MHSectionHeader("Recent Marks")
            }
        }
    }

    private func totals(in range: ClosedRange<String>) -> [String: Int] {
        var totals = [String: Int]()
        for item in items {
            totals.merge(MarkOperations.countsByDay(for: item, in: range), uniquingKeysWith: +)
        }
        return totals
    }

    private func grid(days: [Day], counts: [String: Int]) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: Self.daysPerWeek), spacing: 0) {
            ForEach(days.prefix(Self.daysPerWeek)) { day in
                Text(day.date, format: .dateTime.weekday(.narrow))
                    .mhTextStyle(.caption, colorRole: .secondaryText)
                    .accessibilityHidden(true)
            }
            ForEach(days) { day in
                if day.key <= today {
                    dayButton(day, count: counts[day.key, default: 0])
                } else {
                    Color.clear.accessibilityHidden(true)
                }
            }
        }
    }

    private func dayButton(_ day: Day, count: Int) -> some View {
        Button {
            selectDay(day.key)
        } label: {
            Text(day.date, format: .dateTime.day())
                .font(.caption.monospacedDigit())
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, minHeight: LibraryLayout.minimumControlSize)
                .background {
                    RoundedRectangle(cornerRadius: Self.cornerRadius)
                        .fill(cellColor(count))
                        .padding(Self.cellInset)
                }
                .overlay {
                    if day.key == today {
                        RoundedRectangle(cornerRadius: Self.cornerRadius)
                            .strokeBorder(Color.primary)
                            .padding(Self.cellInset)
                    }
                }
                .overlay(alignment: .bottom) {
                    if count > 0 {
                        Circle()
                            .frame(width: Self.dotSize, height: Self.dotSize)
                            .padding(.bottom, Self.cornerRadius)
                    }
                }
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(day.date, format: .dateTime.year().month().day().weekday(.wide)))
        .accessibilityValue(Text("\(count) Marks"))
    }

    private func cellColor(_ count: Int) -> Color {
        guard count > 0 else {
            return .secondary.opacity(Self.emptyOpacity)
        }
        let intensity = Double(min(count, Self.maximumIntensity))
        return Color.markActionAccent.opacity(Self.opacityStep * intensity)
    }
}
