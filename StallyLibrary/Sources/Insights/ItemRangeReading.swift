//
//  ItemRangeReading.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

struct ItemRangeReading {
    let item: Item
    let rangeMarkedDays: [LocalDay]
    let allMarkedDays: [LocalDay]

    var rangeMarkCount: Int {
        rangeMarkedDays.count
    }

    var totalMarkCount: Int {
        allMarkedDays.count
    }

    var lastMarkedDay: LocalDay? {
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
