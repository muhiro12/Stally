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
    public internal(set) var uuid = UUID()
    /// User-facing item name.
    public internal(set) var name: String = ""
    /// Persisted raw value for `category`.
    public internal(set) var categoryRawValue: String = ItemCategory.other.rawValue
    /// Optional user note that gives the item more context.
    public internal(set) var note: String = ""
    /// Optional visual context for recognizing the item later.
    @Attribute(.externalStorage)
    public internal(set) var photoData: Data?
    /// Date when the item was added.
    public internal(set) var createdAt = Date()
    /// Date when the item was moved into Archive.
    public internal(set) var archivedAt: Date?

    // CloudKit requires SwiftData relationships to be optional.
    // swiftlint:disable discouraged_optional_collection
    @Relationship(deleteRule: .cascade, inverse: \ItemMark.item)
    var markRecords: [ItemMark]?
    // swiftlint:enable discouraged_optional_collection

    /// Calendar-day marks attached to this item.
    public internal(set) var marks: [ItemMark] {
        get {
            markRecords ?? []
        }
        set {
            markRecords = newValue
        }
    }

    /// The preserved product category for this item.
    public internal(set) var category: ItemCategory {
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
        markRecords = []
    }

    func historySnapshot(
        today: LocalDay
    ) -> ItemHistorySnapshot {
        .init(item: self, today: today)
    }

    func mark(on day: LocalDay) -> ItemMark? {
        marks.first { mark in
            mark.day == day
        }
    }

    func isMarked(on day: LocalDay) -> Bool {
        mark(on: day) != nil
    }

    func addMark(on day: LocalDay) -> ItemMark? {
        guard mark(on: day) == nil else {
            return nil
        }

        let mark = ItemMark(
            day: day,
            createdAt: .now,
            item: self,
            uuid: .init()
        )
        marks.append(mark)
        return mark
    }

    func removeMarks(on day: LocalDay) -> [ItemMark] {
        let existingMarks = marks.filter { mark in
            mark.day == day
        }

        marks.removeAll { mark in
            mark.day == day
        }

        return existingMarks
    }
}
