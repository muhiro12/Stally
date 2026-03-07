import Foundation
import SwiftData

/// Domain mutations for creating, updating, archiving, and seeding items.
public enum ItemService {
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

    public static func archive(
        context: ModelContext,
        item: Item,
        at date: Date = .now
    ) throws {
        item.archive(at: date)
        try context.save()
    }

    public static func unarchive(
        context: ModelContext,
        item: Item,
        at date: Date = .now
    ) throws {
        item.unarchive(at: date)
        try context.save()
    }

    public static func delete(
        context: ModelContext,
        item: Item
    ) throws {
        context.delete(item)
        try context.save()
    }

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

        let coat = try create(
            context: context,
            input: .init(
                name: "Black Wool Coat",
                category: .clothing,
                note: "The one I reach for on cold mornings."
            ),
            createdAt: shifted(
                dayOffset: -140,
                from: referenceDate,
                calendar: calendar
            )
        )
        let sneakers = try create(
            context: context,
            input: .init(
                name: "White Everyday Sneakers",
                category: .shoes,
                note: "Easy pair for short walks and errands."
            ),
            createdAt: shifted(
                dayOffset: -90,
                from: referenceDate,
                calendar: calendar
            )
        )
        let tote = try create(
            context: context,
            input: .init(
                name: "Canvas Tote",
                category: .bags,
                note: "Usually comes with me when I need one extra layer."
            ),
            createdAt: shifted(
                dayOffset: -60,
                from: referenceDate,
                calendar: calendar
            )
        )
        let notebook = try create(
            context: context,
            input: .init(
                name: "Daily Field Notes",
                category: .notebooks,
                note: "Still waiting for its first stretch of regular use."
            ),
            createdAt: shifted(
                dayOffset: -35,
                from: referenceDate,
                calendar: calendar
            )
        )
        let archiveItem = try create(
            context: context,
            input: .init(
                name: "Travel Weekender",
                category: .bags,
                note: "Archived because it only comes out a few times a year."
            ),
            createdAt: shifted(
                dayOffset: -200,
                from: referenceDate,
                calendar: calendar
            )
        )

        try MarkService.mark(
            context: context,
            item: coat,
            on: shifted(dayOffset: -18, from: referenceDate, calendar: calendar)
        )
        try MarkService.mark(
            context: context,
            item: coat,
            on: shifted(dayOffset: -6, from: referenceDate, calendar: calendar)
        )
        try MarkService.mark(
            context: context,
            item: coat,
            on: referenceDate
        )

        try MarkService.mark(
            context: context,
            item: sneakers,
            on: shifted(dayOffset: -20, from: referenceDate, calendar: calendar)
        )
        try MarkService.mark(
            context: context,
            item: sneakers,
            on: shifted(dayOffset: -13, from: referenceDate, calendar: calendar)
        )
        try MarkService.mark(
            context: context,
            item: sneakers,
            on: shifted(dayOffset: -1, from: referenceDate, calendar: calendar)
        )

        try MarkService.mark(
            context: context,
            item: tote,
            on: shifted(dayOffset: -45, from: referenceDate, calendar: calendar)
        )
        try MarkService.mark(
            context: context,
            item: tote,
            on: shifted(dayOffset: -11, from: referenceDate, calendar: calendar)
        )

        try MarkService.mark(
            context: context,
            item: archiveItem,
            on: shifted(dayOffset: -90, from: referenceDate, calendar: calendar)
        )
        try MarkService.mark(
            context: context,
            item: archiveItem,
            on: shifted(dayOffset: -65, from: referenceDate, calendar: calendar)
        )
        try archive(
            context: context,
            item: archiveItem,
            at: shifted(dayOffset: -10, from: referenceDate, calendar: calendar)
        )

        _ = notebook
    }
}

private extension ItemService {
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
