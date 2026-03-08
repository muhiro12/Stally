import Foundation
import SwiftData

/// Domain mutations for creating, updating, archiving, and seeding items.
public enum ItemService {
    /// Creates and saves a new item.
    @discardableResult
    public static func create(
        context: ModelContext,
        input: ItemFormInput,
        createdAt: Date = .now
    ) throws -> Item {
        let validatedInput = try input.validated()
        let item: Item = .init(
            name: validatedInput.name,
            category: validatedInput.category,
            photoData: validatedInput.photoData,
            note: validatedInput.note,
            createdAt: createdAt
        )

        context.insert(item)
        try context.save()

        return item
    }

    /// Updates and saves an existing item.
    public static func update(
        context: ModelContext,
        item: Item,
        input: ItemFormInput,
        updatedAt: Date = .now
    ) throws {
        try item.apply(
            input: input,
            updatedAt: updatedAt
        )
        try context.save()
    }

    /// Archives and saves one item.
    public static func archive(
        context: ModelContext,
        item: Item,
        at date: Date = .now
    ) throws {
        item.archive(at: date)
        try context.save()
    }

    /// Archives and saves multiple items.
    public static func archive(
        context: ModelContext,
        items: [Item],
        at date: Date = .now
    ) throws {
        var seenItemIDs: Set<UUID> = []
        var didChange = false

        for item in items
        where !item.isArchived && seenItemIDs.insert(item.id).inserted {
            item.archive(at: date)
            didChange = true
        }

        if didChange {
            try context.save()
        }
    }

    /// Unarchives and saves one item.
    public static func unarchive(
        context: ModelContext,
        item: Item,
        at date: Date = .now
    ) throws {
        item.unarchive(at: date)
        try context.save()
    }

    /// Unarchives and saves multiple items.
    public static func unarchive(
        context: ModelContext,
        items: [Item],
        at date: Date = .now
    ) throws {
        var seenItemIDs: Set<UUID> = []
        var didChange = false

        for item in items
        where item.isArchived && seenItemIDs.insert(item.id).inserted {
            item.unarchive(at: date)
            didChange = true
        }

        if didChange {
            try context.save()
        }
    }

    /// Deletes and saves one item.
    public static func delete(
        context: ModelContext,
        item: Item
    ) throws {
        context.delete(item)
        try context.save()
    }

    /// Deletes and saves every item in the store.
    public static func deleteAll(
        context: ModelContext
    ) throws {
        let items = try context.fetch(FetchDescriptor<Item>())

        guard !items.isEmpty else {
            return
        }

        for item in items {
            context.delete(item)
        }

        try context.save()
    }

    /// Seeds the library with sample items and marks.
    public static func seedSampleData(
        context: ModelContext,
        ifEmptyOnly: Bool = false,
        referenceDate: Date = .now
    ) throws {
        if ifEmptyOnly {
            let itemCount = try context.fetchCount(FetchDescriptor<Item>())

            guard itemCount == .zero else {
                return
            }
        }

        let calendar: Calendar = .current
        let sampleItems = try createSampleItems(
            context: context,
            referenceDate: referenceDate,
            calendar: calendar
        )
        try addSampleMarks(
            context: context,
            sampleItems: sampleItems,
            referenceDate: referenceDate,
            calendar: calendar
        )
    }
}

private extension ItemService {
    static func createSampleItems(
        context: ModelContext,
        referenceDate: Date,
        calendar: Calendar
    ) throws -> [String: Item] {
        try sampleItemDefinitions().reduce(into: [:]) { partialResult, entry in
            partialResult[entry.key] = try makeSampleItem(
                context: context,
                input: entry.value.input,
                dayOffset: entry.value.dayOffset,
                reference: (referenceDate, calendar)
            )
        }
    }

    static func addSampleMarks(
        context: ModelContext,
        sampleItems: [String: Item],
        referenceDate: Date,
        calendar: Calendar
    ) throws {
        guard let coat = sampleItems["coat"],
              let sneakers = sampleItems["sneakers"],
              let tote = sampleItems["tote"],
              let archiveItem = sampleItems["archive"]
        else {
            return
        }

        try mark(
            context: context,
            item: coat,
            dayOffsets: [-18, -6, 0],
            referenceDate: referenceDate,
            calendar: calendar
        )
        try mark(
            context: context,
            item: sneakers,
            dayOffsets: [-20, -13, -1],
            referenceDate: referenceDate,
            calendar: calendar
        )
        try mark(
            context: context,
            item: tote,
            dayOffsets: [-45, -11],
            referenceDate: referenceDate,
            calendar: calendar
        )
        try mark(
            context: context,
            item: archiveItem,
            dayOffsets: [-90, -65],
            referenceDate: referenceDate,
            calendar: calendar
        )
        try archive(
            context: context,
            item: archiveItem,
            at: shifted(
                dayOffset: -10,
                from: referenceDate,
                calendar: calendar
            )
        )
    }

    static func makeSampleItem(
        context: ModelContext,
        input: ItemFormInput,
        dayOffset: Int,
        reference: (date: Date, calendar: Calendar)
    ) throws -> Item {
        try create(
            context: context,
            input: input,
            createdAt: shifted(
                dayOffset: dayOffset,
                from: reference.date,
                calendar: reference.calendar
            )
        )
    }

    static func sampleItemDefinitions() -> [String: (
        input: ItemFormInput,
        dayOffset: Int
    )] {
        [
            "coat": (
                .init(
                    name: "Black Wool Coat",
                    category: .clothing,
                    note: "The one I reach for on cold mornings."
                ),
                -140
            ),
            "sneakers": (
                .init(
                    name: "White Everyday Sneakers",
                    category: .shoes,
                    note: "Easy pair for short walks and errands."
                ),
                -90
            ),
            "tote": (
                .init(
                    name: "Canvas Tote",
                    category: .bags,
                    note: "Usually comes with me when I need one extra layer."
                ),
                -60
            ),
            "notebook": (
                .init(
                    name: "Daily Field Notes",
                    category: .notebooks,
                    note: "Still waiting for its first stretch of regular use."
                ),
                -35
            ),
            "archive": (
                .init(
                    name: "Travel Weekender",
                    category: .bags,
                    note: "Archived because it only comes out a few times a year."
                ),
                -200
            )
        ]
    }

    static func mark(
        context: ModelContext,
        item: Item,
        dayOffsets: [Int],
        referenceDate: Date,
        calendar: Calendar
    ) throws {
        for dayOffset in dayOffsets {
            let date = dayOffset == .zero
                ? referenceDate
                : shifted(
                    dayOffset: dayOffset,
                    from: referenceDate,
                    calendar: calendar
                )

            try MarkService.mark(
                context: context,
                item: item,
                on: date
            )
        }
    }

    static func shifted(
        dayOffset: Int,
        from date: Date,
        calendar: Calendar
    ) -> Date {
        guard let shiftedDate = calendar.date(
            byAdding: .day,
            value: dayOffset,
            to: date
        ) else {
            preconditionFailure("Failed to shift \(date) by \(dayOffset) days.")
        }

        return shiftedDate
    }
}
