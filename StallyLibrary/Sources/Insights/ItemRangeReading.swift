//
//  ItemRangeReading.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

import Foundation

struct ItemRangeReading {
    let item: Item
    let rangeMarkedDays: [Date]
    let allMarkedDays: [Date]

    var rangeMarkCount: Int {
        rangeMarkedDays.count
    }

    var totalMarkCount: Int {
        allMarkedDays.count
    }

    var lastMarkedDay: Date? {
        allMarkedDays.last
    }

    var summary: ItemInsightSummary {
        .init(
            item: item,
            marksInRange: rangeMarkCount,
            totalMarks: totalMarkCount,
            lastMarkedDay: lastMarkedDay
        )
    }
}
