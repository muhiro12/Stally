//
//  TrackedItem.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/03/07.
//

import Foundation
import SwiftData

@Model
final class TrackedItem {
    var name: String
    var createdAt: Date
    var totalCount: Int
    var lastCountedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \CountEntry.item)
    var countEntries: [CountEntry]

    var lastCountedAtText: String {
        if let lastCountedAt {
            StallyDateFormatting.timestampText(for: lastCountedAt)
        } else {
            "未記録"
        }
    }

    var sortedCountEntries: [CountEntry] {
        countEntries.sorted { $0.countedAt > $1.countedAt }
    }

    init(
        name: String,
        createdAt: Date = .now,
        totalCount: Int = 0,
        lastCountedAt: Date? = nil,
        countEntries: [CountEntry] = []
    ) {
        self.name = name
        self.createdAt = createdAt
        self.totalCount = totalCount
        self.lastCountedAt = lastCountedAt
        self.countEntries = countEntries
    }

    func recordCount(at date: Date = .now) {
        countEntries.append(CountEntry(countedAt: date))
        totalCount += 1
        lastCountedAt = date
    }
}
