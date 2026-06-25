//
//  ItemOperations.swift
//  StallyLibrary
//
//  Created by Hiromu Nakano on 2026/06/26.
//

import Foundation
import SwiftData

/// Cross-surface item use cases for Library, item detail, and future system surfaces.
public enum ItemOperations {
    /// Creates and saves a validated Library item.
    @discardableResult
    public static func create(
        context: ModelContext,
        input: ItemFormInput,
        createdAt: Date = .now
    ) throws -> Item {
        let normalizedName = input.normalizedName

        guard !normalizedName.isEmpty else {
            throw ItemValidationError.nameRequired
        }

        let item = Item(
            name: normalizedName,
            category: input.category,
            note: input.normalizedNote,
            createdAt: createdAt
        )
        context.insert(item)
        try context.save()

        return item
    }

    /// Returns whether an item is marked for a calendar day.
    public static func isMarked(
        _ item: Item,
        on date: Date = .now,
        calendar: Calendar = .current
    ) -> Bool {
        item.isMarked(on: date, calendar: calendar)
    }

    /// Adds one mark for a calendar day and saves the context.
    @discardableResult
    public static func mark(
        _ item: Item,
        on date: Date,
        context: ModelContext,
        calendar: Calendar = .current
    ) throws -> Bool {
        guard let mark = item.addMark(on: date, calendar: calendar) else {
            return false
        }

        context.insert(mark)
        try context.save()

        return true
    }

    /// Removes the mark for a calendar day and saves the context.
    @discardableResult
    public static func undoMark(
        _ item: Item,
        on date: Date,
        context: ModelContext,
        calendar: Calendar = .current
    ) throws -> Bool {
        guard let mark = item.removeMark(on: date, calendar: calendar) else {
            return false
        }

        context.delete(mark)
        try context.save()

        return true
    }

    /// Builds the current item-level history reading.
    public static func historySnapshot(
        for item: Item,
        calendar: Calendar = .current,
        now: Date = .now
    ) -> ItemHistorySnapshot {
        .init(item: item, calendar: calendar, now: now)
    }
}
