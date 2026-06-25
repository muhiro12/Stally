//
//  QuietHistoryDayCell.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import SwiftUI

struct QuietHistoryDayCell: View {
    private enum Layout {
        static let verticalSpacing: CGFloat = 4
        static let unmarkedOpacity = 0.2
        static let circleSize: CGFloat = 14
    }

    let day: QuietHistoryDay

    var body: some View {
        VStack(spacing: Layout.verticalSpacing) {
            Circle()
                .fill(day.isMarked ? Color.accentColor : Color.secondary.opacity(Layout.unmarkedOpacity))
                .frame(width: Layout.circleSize, height: Layout.circleSize)

            Text(day.day, format: .dateTime.day())
                .font(.caption2)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(day.day, format: .dateTime.month().day().year()))
        .accessibilityValue(day.isMarked ? Text("Marked") : Text("Not marked"))
    }
}
