//
//  ItemHistorySnapshot.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import Foundation

struct ItemHistorySnapshot {
    private enum Defaults {
        static let shortWindowDayCount = 30
        static let mediumWindowDayCount = 90
        static let inclusiveWindowAdjustment = 1
    }

    let totalMarks: Int
    let lastMarkedDay: Date?
    let marksInLast30Days: Int
    let marksInLast90Days: Int
    let monthsUsed: Int
    let daysSinceLastMark: Int?
    let markedDays: [Date]

    init(item: Item, calendar: Calendar = .current, now: Date = .now) {
        let today = calendar.startOfDay(for: now)
        let uniqueDays = Set(
            item.marks.map { mark in
                calendar.startOfDay(for: mark.day)
            }
        )
        let sortedDays = uniqueDays.sorted(by: >)

        totalMarks = uniqueDays.count
        lastMarkedDay = sortedDays.first
        marksInLast30Days = Self.countMarks(
            in: uniqueDays,
            from: today,
            numberOfDays: Defaults.shortWindowDayCount,
            calendar: calendar
        )
        marksInLast90Days = Self.countMarks(
            in: uniqueDays,
            from: today,
            numberOfDays: Defaults.mediumWindowDayCount,
            calendar: calendar
        )
        monthsUsed = Self.countMonthsUsed(in: uniqueDays, calendar: calendar)
        daysSinceLastMark = lastMarkedDay.map { lastMarkedDay in
            calendar.dateComponents([.day], from: lastMarkedDay, to: today).day ?? 0
        }
        markedDays = sortedDays
    }

    private static func countMarks(
        in markedDays: Set<Date>,
        from today: Date,
        numberOfDays: Int,
        calendar: Calendar
    ) -> Int {
        guard let startDay = calendar.date(
            byAdding: .day,
            value: -(numberOfDays - Defaults.inclusiveWindowAdjustment),
            to: today
        ) else {
            return 0
        }

        return markedDays.filter { day in
            day >= startDay && day <= today
        }
        .count
    }

    private static func countMonthsUsed(
        in markedDays: Set<Date>,
        calendar: Calendar
    ) -> Int {
        let monthKeys = markedDays.map { day in
            let components = calendar.dateComponents([.year, .month], from: day)
            return "\(components.year ?? 0)-\(components.month ?? 0)"
        }

        return Set(monthKeys).count
    }
}
