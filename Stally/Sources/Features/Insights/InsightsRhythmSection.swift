//
//  InsightsRhythmSection.swift
//  Stally
//
//  Created by Codex on 2026/07/13.
//

import Foundation
import MHUI
import SwiftUI

struct InsightsRhythmSection: View {
    @Environment(\.locale)
    private var locale

    let weekdayActivity: [WeekdayActivity]
    let monthlyActivity: [MonthlyActivity]

    var body: some View {
        Section {
            if weekdayActivity.isEmpty, monthlyActivity.isEmpty {
                Text("No weekday pattern yet.")
                    .mhRowSupporting()
            }

            if !weekdayActivity.isEmpty {
                Text("Weekdays")
                    .mhRowTitle()

                ForEach(weekdayActivity) { activity in
                    LabeledContent(weekdayName(activity.weekday)) {
                        Text(activity.markCount, format: .number)
                    }
                }
            }

            if !monthlyActivity.isEmpty {
                Text("Months")
                    .mhRowTitle()

                ForEach(monthlyActivity) { activity in
                    LabeledContent(monthName(activity)) {
                        Text(activity.markCount, format: .number)
                    }
                }
            }
        } header: {
            StallySectionHeader("Rhythm")
        }
    }
}

private extension InsightsRhythmSection {
    func weekdayName(_ weekday: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        let symbols = formatter.weekdaySymbols ?? []
        let index = weekday - 1

        guard symbols.indices.contains(index) else {
            return String(weekday)
        }

        return symbols[index]
    }

    func monthName(_ activity: MonthlyActivity) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale

        guard let date = calendar.date(
            from: .init(year: activity.year, month: activity.month)
        ) else {
            return String(format: "%04d-%02d", activity.year, activity.month)
        }

        return date.formatted(.dateTime.year().month(.wide).locale(locale))
    }
}
