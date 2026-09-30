import Foundation
import SwiftData

enum ItemSeedBuilder {
    static func makeItem(
        from seed: SampleDataSeed,
        referenceDate: Date,
        calendar: Calendar,
        context: ModelContext,
        markIdentifier: (Int) -> UUID
    ) throws -> Item {
        guard let today = LocalDay(containing: referenceDate, in: calendar.timeZone),
              seed.tracking.recordsMarks || seed.markedDaysAgo.isEmpty,
              seed.tracking.start.map({ $0.earliestDay <= today }) ?? true else {
            throw CocoaError(.coderInvalidValue)
        }
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

        item.recordsMarks = seed.tracking.recordsMarks
        item.startRawValue = seed.tracking.start?.rawValue

        for (offset, markedDaysAgo) in seed.markedDaysAgo.enumerated() {
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
                uuid: markIdentifier(offset)
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
