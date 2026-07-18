//
//  QuietHistoryDayCell.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import MHUI
import SwiftUI

struct QuietHistoryDayCell: View {
    private enum Layout {
        static let verticalSpacing: CGFloat = 4
        static let unmarkedOpacity = 0.2
        static let circleSize: CGFloat = 14
    }

    @Environment(\.timeZone)
    private var timeZone

    let day: QuietHistoryDay

    var body: some View {
        VStack(spacing: Layout.verticalSpacing) {
            Circle()
                .mhForegroundStyle(day.isMarked ? .accent : .secondaryText)
                .opacity(day.isMarked ? 1 : Layout.unmarkedOpacity)
                .frame(width: Layout.circleSize, height: Layout.circleSize)

            if let date = day.day.date(in: timeZone) {
                Text(date, format: .dateTime.day())
                    .monospacedDigit()
                    .mhTextStyle(.caption, colorRole: .secondaryText)
            } else {
                Text(day.day.day, format: .number)
                    .monospacedDigit()
                    .mhTextStyle(.caption, colorRole: .secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(day.isMarked ? Text("Marked") : Text("Not marked"))
    }

    private var accessibilityLabel: Text {
        if let date = day.day.date(in: timeZone) {
            return Text(date, format: .dateTime.month().day().year())
        }

        return Text(verbatim: day.day.iso8601Date)
    }
}
