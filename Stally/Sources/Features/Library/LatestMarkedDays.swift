//
//  LatestMarkedDays.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import MHUI
import SwiftUI

struct LatestMarkedDays: View {
    private enum Layout {
        static let verticalSpacing: CGFloat = 8
    }

    @Environment(\.timeZone)
    private var timeZone

    let days: [LocalDay]

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
            Text("Latest marks")
                .mhRowOverline()

            ForEach(days, id: \.self) { day in
                if let date = day.date(in: timeZone) {
                    Text(date, format: .dateTime.month().day().year())
                        .mhRowSupporting()
                } else {
                    Text(verbatim: day.iso8601Date)
                        .mhRowSupporting()
                }
            }
        }
    }
}
