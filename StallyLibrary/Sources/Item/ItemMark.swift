//
//  ItemMark.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import Foundation
import SwiftData

/// A single calendar-day record that an item was chosen.
@Model
public final class ItemMark {
    private static let defaultDayKey = 19_700_101

    /// Stable mark identifier for backups and cross-surface references.
    public internal(set) var uuid = UUID()
    /// Compact proleptic Gregorian day representation used by SwiftData.
    var dayKey = defaultDayKey
    /// Date when this mark record was created.
    public internal(set) var createdAt = Date()
    /// The item this mark belongs to.
    public internal(set) var item: Item?

    /// Timezone-independent calendar day when the item was chosen.
    public var day: LocalDay {
        guard let localDay = LocalDay(dayKey: dayKey) else {
            preconditionFailure("ItemMark contains an invalid day key: \(dayKey)")
        }

        return localDay
    }

    /// Creates a mark for a calendar day.
    init(
        day: LocalDay,
        createdAt: Date,
        item: Item?,
        uuid: UUID
    ) {
        self.uuid = uuid
        dayKey = day.dayKey
        self.createdAt = createdAt
        self.item = item
    }
}
