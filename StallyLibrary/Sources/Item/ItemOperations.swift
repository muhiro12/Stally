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
            createdAt: createdAt,
            uuid: .init(),
            photoData: input.photoData,
            archivedAt: nil
        )
        context.insert(item)
        try saveOrRollback(context)

        return item
    }

    /// Returns active Library items in newest-created order.
    public static func activeItems(from items: [Item]) -> [Item] {
        items
            .filter { item in
                !item.isArchived
            }
            .sorted { lhsItem, rhsItem in
                lhsItem.createdAt > rhsItem.createdAt
            }
    }

    /// Fetches Library items in newest-created order for app and system surfaces.
    public static func items(context: ModelContext) throws -> [Item] {
        var descriptor = FetchDescriptor<Item>(
            sortBy: [
                .init(\.createdAt, order: .reverse)
            ]
        )
        descriptor.includePendingChanges = true
        return try context.fetch(descriptor)
    }

    /// Fetches the item with a stable cross-surface identifier.
    public static func item(
        context: ModelContext,
        uuid: UUID
    ) throws -> Item? {
        try items(context: context).first { item in
            item.uuid == uuid
        }
    }

    /// Fetches items whose user-facing name matches the query.
    public static func items(
        context: ModelContext,
        matchingName query: String
    ) throws -> [Item] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedQuery.isEmpty else {
            return try items(context: context)
        }

        return try items(context: context).filter { item in
            item.name.localizedCaseInsensitiveContains(normalizedQuery)
        }
    }

    /// Updates editable item context while preserving identity and history.
    public static func update(
        _ item: Item,
        input: ItemFormInput,
        context: ModelContext
    ) throws {
        let normalizedName = input.normalizedName

        guard !normalizedName.isEmpty else {
            throw ItemValidationError.nameRequired
        }

        item.name = normalizedName
        item.category = input.category
        item.note = input.normalizedNote
        item.photoData = input.photoData
        try saveOrRollback(context)
    }

    /// Deletes an item and every mark attached to it.
    public static func delete(
        _ item: Item,
        context: ModelContext
    ) throws {
        for mark in item.marks {
            context.delete(mark)
        }

        context.delete(item)
        try saveOrRollback(context)
    }

    /// Returns archived items in newest-archived order.
    public static func archivedItems(from items: [Item]) -> [Item] {
        items
            .filter(\.isArchived)
            .sorted { lhsItem, rhsItem in
                let lhsArchivedAt = lhsItem.archivedAt ?? lhsItem.createdAt
                let rhsArchivedAt = rhsItem.archivedAt ?? rhsItem.createdAt
                return lhsArchivedAt > rhsArchivedAt
            }
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
        guard !item.isArchived else {
            throw ItemValidationError.archivedItemsCannotChangeHistory
        }

        guard let mark = item.addMark(on: date, calendar: calendar) else {
            return false
        }

        context.insert(mark)
        try saveOrRollback(context)

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
        guard !item.isArchived else {
            throw ItemValidationError.archivedItemsCannotChangeHistory
        }

        let marks = item.removeMarks(on: date, calendar: calendar)

        guard !marks.isEmpty else {
            return false
        }

        for mark in marks {
            context.delete(mark)
        }
        try saveOrRollback(context)

        return true
    }

    /// Moves an active item into Archive while preserving its context and marks.
    @discardableResult
    public static func archive(
        _ item: Item,
        on date: Date,
        context: ModelContext
    ) throws -> Bool {
        guard !item.isArchived else {
            return false
        }

        item.archivedAt = date
        try saveOrRollback(context)

        return true
    }

    /// Moves an archived item back to the active Library.
    @discardableResult
    public static func moveBackToLibrary(
        _ item: Item,
        context: ModelContext
    ) throws -> Bool {
        guard item.isArchived else {
            return false
        }

        item.archivedAt = nil
        try saveOrRollback(context)

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

    private static func saveOrRollback(_ context: ModelContext) throws {
        try saveOrRollback(context) { context in
            try context.save()
        }
    }

    static func saveOrRollback(
        _ context: ModelContext,
        saving save: (ModelContext) throws -> Void
    ) throws {
        do {
            try save(context)
        } catch {
            context.rollback()
            throw error
        }
    }
}
