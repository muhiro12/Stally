import Foundation
import SwiftData

/// Domain mutations for adding and removing daily marks.
public enum MarkService {
    public enum MutationError: LocalizedError, Equatable {
        case archivedItem

        public var errorDescription: String? {
            switch self {
            case .archivedItem:
                "Archived items are read-only. Move this item back to Home to change its marks."
            }
        }
    }

    /// Creates a mark for the given day when missing, or returns the existing one.
    @discardableResult
    public static func mark(
        context: ModelContext,
        item: Item,
        on date: Date = .now,
        calendar: Calendar = .current
    ) throws -> Mark {
        try validateMutationTarget(item)

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

    /// Removes the mark for the given day when it exists.
    @discardableResult
    public static func unmark(
        context: ModelContext,
        item: Item,
        on date: Date = .now,
        calendar: Calendar = .current
    ) throws -> Bool {
        try validateMutationTarget(item)

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
        try validateMutationTarget(item)

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
    static func validateMutationTarget(
        _ item: Item
    ) throws {
        guard !item.isArchived else {
            throw MutationError.archivedItem
        }
    }

    static func existingMark(
        for item: Item,
        storageDate: Date
    ) -> Mark? {
        item.marks.first { mark in
            mark.day == storageDate
        }
    }
}
