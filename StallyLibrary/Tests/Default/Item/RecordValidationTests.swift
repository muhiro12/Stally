import Foundation
import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct RecordValidationTests {
    @Test(arguments: ["2024-02-29", "2024-02-29T00:00", "2024-02-29T23:59", "0001-01-01"])
    func validMarks(_ value: String) throws {
        try CivilDate.validateMark(value)
    }

    @Test(arguments: [
        "", "2023-02-29", "2024-2-09", "2024-04-31", "2024-01-01T24:00", "2024-01-01T12:60",
        "2024-01-01T12:00Z", "2024-01-01T12:00:01", "0000-01-01"
    ])
    func invalidMarks(_ value: String) {
        #expect(throws: RecordError.invalidDate) { try CivilDate.validateMark(value) }
    }

    @Test
    func partialReversalOverlapAndSameDayBoundary() throws {
        let container = try StallyModelContainerFactory.inMemory()
        let context = ModelContext(container)
        let item = try ItemOperations.create(context: context, name: "Periods")
        let first = try PeriodOperations.add(
            to: item,
            input: .init(start: "2024-05", end: "2024", isOngoing: false),
            today: "2026-10-27",
            context: context
        )
        #expect(throws: RecordError.invalidPeriod) {
            try PeriodOperations.correct(
                first,
                input: .init(start: "2024-06", end: "2024-05", isOngoing: false),
                today: "2026-10-27",
                context: context
            )
        }
        #expect(first.startLocalDate == "2024-05" && first.endLocalDate == "2024")
        try PeriodOperations.correct(
            first,
            input: .init(start: "2024-05-01", end: "2024-05-10", isOngoing: false),
            today: "2026-10-27",
            context: context
        )
        #expect(throws: RecordError.overlappingPeriods) {
            try PeriodOperations.add(
                to: item,
                input: .init(start: "2024-05-09", end: "2024-05-11", isOngoing: false),
                today: "2026-10-27",
                context: context
            )
        }
        let second = try PeriodOperations.resume(
            first,
            on: "2024-05-10",
            today: "2026-10-27",
            context: context
        )
        #expect(item.periods?.count == 2)
        try PeriodOperations.end(second, on: nil, today: "2026-10-27", context: context)
        #expect(!second.isOngoing && second.endLocalDate == nil)
        try PeriodOperations.delete(second, context: context)
        #expect(item.periods?.count == 1)
    }

    @Test
    func incomingConflictsAndOrphansAreNotRepaired() throws {
        let container = try StallyModelContainerFactory.inMemory()
        let context = ModelContext(container)
        let item = try ItemOperations.create(context: context, name: "Conflicting")
        let first = ItemPeriod(item: item, startLocalDate: nil, endLocalDate: nil, isOngoing: true)
        let second = ItemPeriod(item: item, startLocalDate: nil, endLocalDate: nil, isOngoing: true)
        let orphan = ItemMark(item: item, localDateTime: "unresolved incoming date")
        context.insert(first)
        context.insert(second)
        context.insert(orphan)
        orphan.item = nil
        try context.save()
        #expect(throws: RecordError.ongoingPeriodExists) {
            try PeriodOperations.add(to: item, input: .init(), today: "2026-10-27", context: context)
        }
        #expect(item.periods?.count == 2)
        #expect(orphan.item == nil && orphan.localDateTime == "unresolved incoming date")
        try PeriodOperations.end(first, on: nil, today: "2026-10-27", context: context)
        #expect(!first.isOngoing && second.isOngoing)
    }
}
