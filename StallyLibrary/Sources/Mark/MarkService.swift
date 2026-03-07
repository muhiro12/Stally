import Foundation
import SwiftData

/// Domain mutations for adding and removing daily marks.
public enum MarkService {
    @discardableResult
    public static func mark(
        context: ModelContext,
        item: Item,
        on date: Date = .now,
        calendar: Calendar = .current
    ) throws -> Mark {
        let storageDate = DayStamp.storageDate(
            from: date,
            calendar: calendar
        )

        if let existingMark = existingMark(
            for: item,
            storageDate: storageDate
        ) {
            return existingMark
        }

        let mark: Mark = .init(
            item: item,
            day: storageDate,
            createdAt: date
        )

        context.insert(mark)
        try context.save()

        return mark
    }

    @discardableResult
    public static func unmark(
        context: ModelContext,
        item: Item,
        on date: Date = .now,
        calendar: Calendar = .current
    ) throws -> Bool {
        let storageDate = DayStamp.storageDate(
            from: date,
            calendar: calendar
        )

        guard let mark = existingMark(
            for: item,
            storageDate: storageDate
        ) else {
            return false
        }

        context.delete(mark)
        try context.save()

        return true
    }

    /// Returns `true` when a mark exists after the toggle finishes.
    @discardableResult
    public static func toggle(
        context: ModelContext,
        item: Item,
        on date: Date = .now,
        calendar: Calendar = .current
    ) throws -> Bool {
        let storageDate = DayStamp.storageDate(
            from: date,
            calendar: calendar
        )

        if let mark = existingMark(
            for: item,
            storageDate: storageDate
        ) {
            context.delete(mark)
            try context.save()
            return false
        }

        context.insert(
            Mark(
                item: item,
                day: storageDate,
                createdAt: date
            )
        )
        try context.save()

        return true
    }
}

private extension MarkService {
    static func existingMark(
        for item: Item,
        storageDate: Date
    ) -> Mark? {
        item.marks.first { mark in
            mark.day == storageDate
        }
    }
}
