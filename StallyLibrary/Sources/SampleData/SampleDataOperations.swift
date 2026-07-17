//
//  SampleDataOperations.swift
//  StallyLibrary
//
//  Created by Codex on 2026/07/13.
//

import Foundation
import SwiftData

/// Cross-surface use cases for adding and removing built-in sample records.
public enum SampleDataOperations {
    /// Creates localized sample items when the Library contains no items.
    ///
    /// The samples are ordinary persisted items with representative history
    /// and Archive states. The operation inserts every record before saving
    /// once. If saving fails, the context rolls back the complete sample set.
    /// Calling this operation for a nonempty Library leaves the existing items
    /// unchanged and returns an empty array.
    ///
    /// - Parameters:
    ///   - context: The model context that owns the Library.
    ///   - locale: The locale used to resolve sample names and notes.
    ///   - timeZone: The timezone used to build relative sample history.
    ///   - createdAt: The reference date used to build the sample timeline.
    /// - Returns: The created items, or an empty array when the Library is not empty.
    @discardableResult
    public static func createItemsIfLibraryIsEmpty(
        in context: ModelContext,
        locale: Locale = .current,
        timeZone: TimeZone = .current,
        createdAt: Date = .now
    ) throws -> [Item] {
        try createItemsIfLibraryIsEmpty(
            in: context,
            locale: locale,
            timeZone: timeZone,
            createdAt: createdAt
        ) { context in
            try context.save()
        }
    }

    /// Summarizes built-in sample records without changing them.
    public static func summary(for items: [Item]) -> SampleDataSummary {
        let sampleItems = items.filter { item in
            sampleItemIDs.contains(item.uuid)
        }

        return .init(
            itemCount: sampleItems.count,
            markCount: sampleItems.reduce(0) { result, item in
                result + item.marks.count
            }
        )
    }

    /// Removes every built-in sample item and its marks as one transaction.
    ///
    /// Items created by the user remain untouched. Edits and marks added to a
    /// built-in sample remain associated with its stable identifier and are
    /// removed with that sample. The deletion uses a dedicated model context
    /// so a failed save can be discarded without changing the caller's
    /// context.
    ///
    /// - Parameter context: The model context that owns the Library.
    /// - Returns: Counts of the sample records removed by the operation.
    @discardableResult
    public static func removeSampleItems(
        in context: ModelContext
    ) throws -> SampleDataSummary {
        try removeSampleItems(in: context) { context in
            try context.save()
        }
    }
}

extension SampleDataOperations {
    static func createItemsIfLibraryIsEmpty(
        in context: ModelContext,
        locale: Locale,
        timeZone: TimeZone,
        createdAt: Date,
        saving save: (ModelContext) throws -> Void
    ) throws -> [Item] {
        guard try ItemOperations.items(context: context).isEmpty,
              let today = LocalDay(containing: createdAt, in: timeZone) else {
            return []
        }

        let calendar = calendar(in: timeZone)
        let items = try sampleSeeds(locale: locale).map { seed in
            try makeItem(
                from: seed,
                today: today,
                referenceDate: createdAt,
                calendar: calendar,
                context: context
            )
        }

        try ItemOperations.saveOrRollback(context, saving: save)
        return items
    }

    static func removeSampleItems(
        in context: ModelContext,
        saving save: (ModelContext) throws -> Void
    ) throws -> SampleDataSummary {
        if context.hasChanges {
            try context.save()
        }

        let removalContext = ModelContext(context.container)
        let sampleItems = try ItemOperations.items(context: removalContext).filter { item in
            sampleItemIDs.contains(item.uuid)
        }
        let summary = summary(for: sampleItems)

        guard !summary.isEmpty else {
            return summary
        }

        for item in sampleItems {
            removalContext.delete(item)
        }

        try save(removalContext)
        return summary
    }
}

private extension SampleDataOperations {
    static func makeItem(
        from seed: SampleDataSeed,
        today: LocalDay,
        referenceDate: Date,
        calendar: Calendar,
        context: ModelContext
    ) throws -> Item {
        let item = try ItemOperations.makeItem(
            input: seed.input,
            createdAt: try date(
                seed.createdDaysAgo,
                before: referenceDate,
                calendar: calendar
            ),
            uuid: seed.uuid
        )
        context.insert(item)

        for markedDaysAgo in seed.markedDaysAgo {
            guard let markedDay = today.adding(days: -markedDaysAgo) else {
                throw CocoaError(.coderInvalidValue)
            }

            let mark = ItemMark(
                day: markedDay,
                createdAt: try date(
                    markedDaysAgo,
                    before: referenceDate,
                    calendar: calendar
                ),
                item: item,
                uuid: .init()
            )
            item.marks.append(mark)
            context.insert(mark)
        }

        if let archivedDaysAgo = seed.archivedDaysAgo {
            item.archivedAt = try date(
                archivedDaysAgo,
                before: referenceDate,
                calendar: calendar
            )
        }

        return item
    }

    static func date(
        _ daysAgo: Int,
        before referenceDate: Date,
        calendar: Calendar
    ) throws -> Date {
        guard let date = calendar.date(
            byAdding: .day,
            value: -daysAgo,
            to: referenceDate
        ) else {
            throw CocoaError(.coderInvalidValue)
        }

        return calendar.startOfDay(for: date)
    }

    static func calendar(in timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = .init(identifier: "en_US_POSIX")
        calendar.timeZone = timeZone
        return calendar
    }
}
