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

    @Environment(\.calendar)
    private var calendar

    let markedDays: [Date]

    private var recentDays: [QuietHistoryDay] {
        let today = calendar.startOfDay(for: .now)
        let markedDaySet = Set(
            markedDays.map { day in
                calendar.startOfDay(for: day)
            }
        )

        return (0..<Layout.recentDayCount).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else {
                return nil
            }

            return QuietHistoryDay(day: day, isMarked: markedDaySet.contains(day))
        }
        .reversed()
    }

    private let columns = [
        GridItem(
            .adaptive(
                minimum: Layout.minimumColumnWidth,
                maximum: Layout.maximumColumnWidth
            ),
            spacing: Layout.columnSpacing
        )
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: Layout.rowSpacing) {
            ForEach(recentDays) { day in
                QuietHistoryDayCell(day: day)
            }
        }
    }
}
