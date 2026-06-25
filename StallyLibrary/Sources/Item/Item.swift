//
//  Item.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import Foundation
import SwiftData

/// A personal object the user keeps in the active Library and marks when chosen.
@Model
public final class Item {
    /// User-facing item name.
    public var name: String
    /// Persisted raw value for `category`.
    public var categoryRawValue: String
    /// Optional user note that gives the item more context.
    public var note: String
    /// Date when the item was added.
    public var createdAt: Date

    /// Calendar-day marks attached to this item.
    @Relationship(deleteRule: .cascade, inverse: \ItemMark.item)
    public var marks: [ItemMark]

    /// The preserved product category for this item.
    public var category: ItemCategory {
        get {
            ItemCategory(rawValue: categoryRawValue) ?? .other
        }
        set {
            categoryRawValue = newValue.rawValue
        }
    }

    var sortedMarks: [ItemMark] {
        marks.sorted { lhsMark, rhsMark in
            lhsMark.day > rhsMark.day
        }
    }

    init(
        name: String,
        category: ItemCategory,
        note: String = "",
        createdAt: Date = .now
    ) {
        self.name = name
        categoryRawValue = category.rawValue
        self.note = note
        self.createdAt = createdAt
        marks = []
    }

    func historySnapshot(
        calendar: Calendar = .current,
        now: Date = .now
    ) -> ItemHistorySnapshot {
        .init(item: self, calendar: calendar, now: now)
    }

    func mark(on date: Date, calendar: Calendar = .current) -> ItemMark? {
        let day = calendar.startOfDay(for: date)

        return marks.first { mark in
            calendar.isDate(mark.day, inSameDayAs: day)
        }
    }

    func isMarked(on date: Date, calendar: Calendar = .current) -> Bool {
        mark(on: date, calendar: calendar) != nil
    }

    func addMark(on date: Date, calendar: Calendar = .current) -> ItemMark? {
        let day = calendar.startOfDay(for: date)

        guard mark(on: day, calendar: calendar) == nil else {
            return nil
        }

        let mark = ItemMark(day: day, item: self)
        marks.append(mark)
        return mark
    }

    func removeMark(on date: Date, calendar: Calendar = .current) -> ItemMark? {
        let day = calendar.startOfDay(for: date)

        guard let existingMark = mark(on: day, calendar: calendar) else {
            return nil
        }

        marks.removeAll { mark in
            calendar.isDate(mark.day, inSameDayAs: day)
        }

        return existingMark
    }
}
