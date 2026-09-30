//
//  InsightItemSummaryRow.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHUI
import SwiftUI

struct InsightItemSummaryRow: View {
    @Environment(\.timeZone)
    private var timeZone

    @Environment(Item.self)
    private var item

    let marksInRange: Int
    let lastMarkedDay: LocalDay?

    var body: some View {
        VStack(alignment: .leading) {
            Text(item.name)
                .mhRowTitle()

            HStack {
                Text(item.category.title)

                Text("\(marksInRange) marks")

                if let lastMarkedDay {
                    if let date = lastMarkedDay.date(in: timeZone) {
                        Text(date, format: .dateTime.month().day())
                    } else {
                        Text(verbatim: lastMarkedDay.iso8601Date)
                    }
                }
            }
            .mhRowOverline()
        }
    }
}
