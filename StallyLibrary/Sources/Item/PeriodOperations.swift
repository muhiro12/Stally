import Foundation
import SwiftData

/// Partial-date history with conservative local validation, without repairing incoming conflicts.
public enum PeriodOperations {
    /// Adds period knowledge without inferring missing date components.
    @discardableResult
    public static func add(to item: Item, input: PeriodInput, today: String, context: ModelContext) throws
    -> ItemPeriod {
        try RecordMutation.validate(context, models: [item])
        try validate(
            start: input.start,
            end: input.end,
            isOngoing: input.isOngoing,
            siblings: item.periods ?? [],
            today: today
        )
        let period = ItemPeriod(
            item: item,
            startLocalDate: input.start,
            endLocalDate: input.end,
            isOngoing: input.isOngoing
        )
        context.insert(period)
        try RecordMutation.save(context)
        return period
    }

    /// Ending preserves identity and start. Pass nil when the end date is unknown.
    public static func end(_ period: ItemPeriod, on end: String?, today: String, context: ModelContext) throws {
        try correct(
            period,
            input: .init(start: period.startLocalDate, end: end, isOngoing: false),
            today: today,
            context: context
        )
    }

    /// Genuine resumption creates a new period; a mistaken ending is corrected in place.
    @discardableResult
    public static func resume(_ period: ItemPeriod, on start: String?, today: String, context: ModelContext)
    throws -> ItemPeriod {
        try RecordMutation.validate(context, models: [period])
        guard !period.isOngoing, let item = period.item else {
            throw RecordError.invalidPeriod
        }
        return try add(to: item, input: .init(start: start), today: today, context: context)
    }

    /// Revises the selected period while retaining its UUID and registration time.
    public static func correct(_ period: ItemPeriod, input: PeriodInput, today: String, context: ModelContext)
    throws {
        try RecordMutation.validate(context, models: [period])
        guard let item = period.item else {
            throw RecordError.missingRecord
        }
        let siblings = (item.periods ?? []).filter { $0 !== period }
        try validate(
            start: input.start,
            end: input.end,
            isOngoing: input.isOngoing,
            siblings: siblings,
            today: today
        )
        period.startLocalDate = input.start
        period.endLocalDate = input.end
        period.isOngoing = input.isOngoing
        try RecordMutation.save(context)
    }

    /// Removes this period only; Marks and other periods remain independent.
    public static func delete(_ period: ItemPeriod, context: ModelContext) throws {
        try RecordMutation.validate(context, models: [period])
        context.delete(period)
        try RecordMutation.save(context)
    }
}

private extension PeriodOperations {
    static func validate(
        start: String?,
        end: String?,
        isOngoing: Bool,
        siblings: [ItemPeriod],
        today: String
    ) throws {
        let todayDate = try CivilDate.parse(today, formats: [CivilDate.dayLength: "yyyy-MM-dd"])
        let startRange = try CivilDate.range(start)
        let endRange = try CivilDate.range(end)
        try validateBoundaries(start: startRange, end: endRange, isOngoing: isOngoing)
        var ongoingCount = isOngoing ? 1 : 0
        for sibling in siblings {
            let siblingStart = try CivilDate.range(sibling.startLocalDate)
            let siblingEnd = try CivilDate.range(sibling.endLocalDate)
            try validateBoundaries(start: siblingStart, end: siblingEnd, isOngoing: sibling.isOngoing)
            if sibling.isOngoing {
                ongoingCount += 1
            }
            guard ongoingCount <= 1 else {
                throw RecordError.ongoingPeriodExists
            }
            if let startRange, let siblingStart,
               let earliestEnd = isOngoing ? todayDate : endRange?.start,
               let siblingEarliestEnd = sibling.isOngoing ? todayDate : siblingEnd?.start {
                let latestStart = max(
                    CivilDate.latestDay(in: startRange),
                    CivilDate.latestDay(in: siblingStart)
                )
                if latestStart < min(earliestEnd, siblingEarliestEnd) {
                    throw RecordError.overlappingPeriods
                }
            }
        }
    }

    static func validateBoundaries(start: DateInterval?, end: DateInterval?, isOngoing: Bool)
    throws {
        guard !isOngoing || end == nil else {
            throw RecordError.invalidPeriod
        }
        if let start, let end, start.start >= end.end {
            throw RecordError.invalidPeriod
        }
    }
}
