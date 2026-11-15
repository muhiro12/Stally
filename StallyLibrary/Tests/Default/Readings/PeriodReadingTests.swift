import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct PeriodReadingTests {
    @Test
    func exactCurrentAndCumulativeExcludeGaps() throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let item = try ItemOperations.create(context: context, name: "Time")
        #expect(try PeriodReadingOperations.readings(for: item, today: "2026-10-31").cumulative == nil)
        try PeriodOperations.add(
            to: item,
            input: .init(start: "2024-02-28", end: "2024-03-01", isOngoing: false),
            today: "2026-10-31",
            context: context
        )
        try PeriodOperations.add(to: item, input: .init(start: "2026-10-30"), today: "2026-10-31", context: context)
        let readings = try PeriodReadingOperations.readings(for: item, today: "2026-10-31")
        #expect(readings.current?.exactDays == 1)
        #expect(readings.cumulative?.exactDays == 3)
        #expect(readings.cumulative?.hasApproximation == false)
    }

    @Test
    func estimatesUseKnownUnitsAndUnknownHistoryIsExcluded() throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let item = try ItemOperations.create(context: context, name: "Partial")
        try PeriodOperations.add(
            to: item,
            input: .init(start: "2020-12", end: "2021", isOngoing: false),
            today: "2026-10-31",
            context: context
        )
        try PeriodOperations.add(
            to: item,
            input: .init(start: "2022-04-30", end: "2023-05", isOngoing: false),
            today: "2026-10-31",
            context: context
        )
        try PeriodOperations.add(
            to: item,
            input: .init(start: nil, end: nil, isOngoing: false),
            today: "2026-10-31",
            context: context
        )
        let reading = try #require(PeriodReadingOperations.readings(for: item, today: "2026-10-31").cumulative)
        #expect(reading.approximateYears == 1)
        #expect(reading.approximateMonths == 13)
        #expect(reading.excludedCount == 1)
        #expect(reading.includedCount == 2)
        #expect(reading.hasApproximation)
        #expect(!context.hasChanges)
    }

    @Test
    func possibleOverlapIsExplainedAndFutureCurrentDoesNotBecomeZero() throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let item = try ItemOperations.create(context: context, name: "Uncertainty")
        try PeriodOperations.add(
            to: item,
            input: .init(start: "2020", end: "2021", isOngoing: false),
            today: "2026-10-31",
            context: context
        )
        try PeriodOperations.add(
            to: item,
            input: .init(start: "2021", end: "2022", isOngoing: false),
            today: "2026-10-31",
            context: context
        )
        try PeriodOperations.add(to: item, input: .init(start: "2027"), today: "2026-10-31", context: context)
        let readings = try PeriodReadingOperations.readings(for: item, today: "2026-10-31")
        #expect(readings.cumulative?.mayOverlap == true)
        #expect(readings.current?.includedCount == 0)
        #expect(readings.current?.excludedCount == 1)
    }
}
