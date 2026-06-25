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
    /// Stable item identifier for backups, links, and cross-surface references.
    @Attribute(.unique)
    public var uuid: UUID
    /// User-facing item name.
    public var name: String
    /// Persisted raw value for `category`.
    public var categoryRawValue: String
    /// Optional user note that gives the item more context.
    public var note: String
    /// Optional visual context for recognizing the item later.
    public var photoData: Data?
    /// Date when the item was added.
    public var createdAt: Date
    /// Date when the item was moved into Archive.
    public var archivedAt: Date?

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

    /// Whether this item is currently preserved in Archive.
    public var isArchived: Bool {
        archivedAt != nil
    }

    var sortedMarks: [ItemMark] {
        marks.sorted { lhsMark, rhsMark in
            lhsMark.day > rhsMark.day
        }
    }

    init(
        name: String,
        category: ItemCategory,
        note: String,
        createdAt: Date,
        uuid: UUID,
        photoData: Data?,
        archivedAt: Date?
    ) {
        self.uuid = uuid
        self.name = name
        categoryRawValue = category.rawValue
        self.note = note
        self.photoData = photoData
        self.createdAt = createdAt
        self.archivedAt = archivedAt
        marks = []
    }

    func historySnapshot(
        calendar: Calendar,
        now: Date
    ) -> ItemHistorySnapshot {
        .init(item: self, calendar: calendar, now: now)
    }

    func mark(on date: Date, calendar: Calendar) -> ItemMark? {
        let day = calendar.startOfDay(for: date)

        return marks.first { mark in
            calendar.isDate(mark.day, inSameDayAs: day)
        }
    }

    func isMarked(on date: Date, calendar: Calendar) -> Bool {
        mark(on: date, calendar: calendar) != nil
    }

    func addMark(on date: Date, calendar: Calendar) -> ItemMark? {
        let day = calendar.startOfDay(for: date)

        guard mark(on: day, calendar: calendar) == nil else {
            return nil
        }

        let mark = ItemMark(day: day, item: self)
        marks.append(mark)
        return mark
    }

    func removeMark(on date: Date, calendar: Calendar) -> ItemMark? {
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
