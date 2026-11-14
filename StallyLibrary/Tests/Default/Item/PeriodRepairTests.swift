import Foundation
import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct PeriodRepairTests {
    @Test
    func ongoingConflictsCanBeEndedOneAtATimeWithoutRewritingHistory() throws {
        let directory = PersistentTestDirectory.makeURL()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "repair.store")
        let identities = try autoreleasepool {
            let context = ModelContext(try StallyModelContainerFactory.disk(at: url))
            let periods = try savedPeriods([.init(), .init(), .init()], context: context)
            let item = try #require(periods[0].item)
            try MarkOperations.add(to: item, localDateTime: "2026-11-14", context: context)
            let identities = periods.map { ($0.uuid, $0.createdAt) }
            try PeriodOperations.correct(
                periods[0],
                input: .init(isOngoing: false),
                today: "2026-11-14",
                context: context,
                original: .init()
            )
            #expect(periods.filter(\.isOngoing).count == 2)
            #expect(throws: RecordError.ongoingPeriodExists) {
                try PeriodOperations.add(to: item, input: .init(), today: "2026-11-14", context: context)
            }
            #expect(throws: RecordError.ongoingPeriodExists) {
                try PeriodOperations.resume(periods[0], on: nil, today: "2026-11-14", context: context)
            }
            try PeriodOperations.end(periods[1], on: nil, today: "2026-11-14", context: context)
            #expect(periods.filter(\.isOngoing).count == 1)
            #expect(!context.hasChanges)
            return identities
        }
        let reopened = ModelContext(try StallyModelContainerFactory.disk(at: url))
        let saved = try reopened.fetch(FetchDescriptor<ItemPeriod>())
        #expect(saved.count == 3 && saved.filter(\.isOngoing).count == 1)
        for (uuid, createdAt) in identities {
            let period = try #require(saved.first { $0.uuid == uuid })
            #expect(period.createdAt == createdAt)
            #expect(period.startLocalDate == nil && period.endLocalDate == nil)
        }
        #expect(try reopened.fetchCount(FetchDescriptor<ItemMark>()) == 1)
    }

    @Test
    func overlappingHistoryCanBeRepairedByRemovingAndNarrowingConflicts() throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let original = PeriodInput(start: "2020-01-01", end: "2020-12-01", isOngoing: false)
        let periods = try savedPeriods([
            original,
            .init(start: "2020-02-01", end: "2020-03-01", isOngoing: false),
            .init(start: "2020-09-01", end: "2020-10-01", isOngoing: false)
        ], context: context)
        let revised = PeriodInput(start: "2020-04-01", end: "2020-12-01", isOngoing: false)
        try PeriodOperations.correct(
            periods[0], input: revised, today: "2026-11-14", context: context, original: original
        )
        try PeriodOperations.correct(
            periods[0],
            input: .init(start: "2020-04-01", end: "2020-09-15", isOngoing: false),
            today: "2026-11-14",
            context: context,
            original: revised
        )
        let saved = try ModelContext(context.container).fetch(FetchDescriptor<ItemPeriod>())
        #expect(saved.first { $0.uuid == periods[0].uuid }?.endLocalDate == "2020-09-15")
        #expect(saved.first { $0.uuid == periods[1].uuid }?.startLocalDate == "2020-02-01")
        #expect(saved.first { $0.uuid == periods[2].uuid }?.endLocalDate == "2020-10-01")
    }

    @Test(arguments: [
        PeriodInput(start: "2020-04-01", end: "2020-09-01", isOngoing: false),
        PeriodInput(start: "2020-04-01", end: "2020-06-15", isOngoing: false),
        PeriodInput(start: "2020-01-01", end: "2020-06-01", isOngoing: false)
    ])
    func repairsCannotReplaceExpandOrRetainAllConflicts(_ input: PeriodInput) throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let original = PeriodInput(start: "2020-01-01", end: "2020-06-01", isOngoing: false)
        let periods = try savedPeriods([
            original,
            .init(start: "2020-02-01", end: "2020-03-01", isOngoing: false),
            .init(start: "2020-05-01", end: "2020-07-01", isOngoing: false),
            .init(start: "2020-08-01", end: "2020-10-01", isOngoing: false)
        ], context: context)
        #expect(throws: RecordError.overlappingPeriods) {
            try PeriodOperations.correct(
                periods[0], input: input, today: "2026-11-14", context: context, original: original
            )
        }
        #expect(periods[0].startLocalDate == original.start && periods[0].endLocalDate == original.end)
        #expect(!context.hasChanges)
    }

    @Test
    func endingOneConflictCannotIntroduceAnOverlap() throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let periods = try savedPeriods([
            .init(), .init(start: "2021"), .init(start: "2022")
        ], context: context)
        #expect(throws: RecordError.self) {
            try PeriodOperations.correct(
                periods[0],
                input: .init(start: "2020", end: "2025", isOngoing: false),
                today: "2026-11-14",
                context: context,
                original: .init()
            )
        }
        #expect(periods.filter(\.isOngoing).count == periods.count)
        #expect(periods[0].startLocalDate == nil && periods[0].endLocalDate == nil)
        #expect(!context.hasChanges)
    }

    private func savedPeriods(_ inputs: [PeriodInput], context: ModelContext) throws -> [ItemPeriod] {
        let item = try ItemOperations.create(context: context, name: "Incoming conflicts")
        // Model incoming facts directly; ordinary operations must continue rejecting their creation.
        let periods = inputs.map { input in
            let period = ItemPeriod(
                item: item, startLocalDate: input.start, endLocalDate: input.end, isOngoing: input.isOngoing
            )
            context.insert(period)
            return period
        }
        try context.save()
        return periods
    }
}
