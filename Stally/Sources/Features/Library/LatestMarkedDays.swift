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

    let days: [Date]

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
            Text("Latest marks")
                .mhRowOverline()

            ForEach(days, id: \.self) { day in
                Text(day, format: .dateTime.month().day().year())
                    .mhRowSupporting()
            }
        }
    }
}
