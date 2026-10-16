//
//  QuietHistoryGrid.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import SwiftUI

struct QuietHistoryGrid: View {
    private enum Layout {
        static let recentDayCount = 35
        static let minimumColumnWidth: CGFloat = 34
        static let maximumColumnWidth: CGFloat = 44
        static let columnSpacing: CGFloat = 8
        static let rowSpacing: CGFloat = 10
    }

    @Environment(\.timeZone)
    private var timeZone

    @Environment(\.stallyReadingDate)
    private var readingDate

    @ScaledMetric(relativeTo: .caption)
    private var minimumColumnWidth = Layout.minimumColumnWidth
    @ScaledMetric(relativeTo: .caption)
    private var maximumColumnWidth = Layout.maximumColumnWidth

    let markedDays: [LocalDay]

    private var columns: [GridItem] {
        [
            .init(
                .adaptive(
                    minimum: minimumColumnWidth,
                    maximum: maximumColumnWidth
                ),
                spacing: Layout.columnSpacing
            )
        ]
    }

    var body: some View {
        let now = readingDate
        let today = LocalDay(containing: now, in: timeZone)

        LazyVGrid(columns: columns, spacing: Layout.rowSpacing) {
            if let today {
                ForEach(recentDays(from: today)) { day in
                    QuietHistoryDayCell(day: day)
                }
            }
        }
    }

    private func recentDays(from today: LocalDay) -> [QuietHistoryDay] {
        let markedDaySet = Set(markedDays)
        let days = (0..<Layout.recentDayCount).compactMap { offset -> QuietHistoryDay? in
            guard let day = today.adding(days: -offset) else {
                return nil
            }

            return QuietHistoryDay(day: day, isMarked: markedDaySet.contains(day))
        }

        return days.reversed()
    }
}
