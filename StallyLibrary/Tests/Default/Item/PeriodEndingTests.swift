import Foundation
import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct PeriodEndingTests {
    @Test(arguments: [false, true])
    func staleEndingPreservesAnInterveningCorrectionAfterReopen(alreadyEnded: Bool) throws {
        let directory = PersistentTestDirectory.makeURL()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: "period-ending.store")
        let identity = try autoreleasepool {
            let container = try StallyModelContainerFactory.disk(at: url)
            let context = container.mainContext
            context.autosaveEnabled = false
            let item = try ItemOperations.create(context: context, name: "History")
            let period = try PeriodOperations.add(
                to: item, input: .init(start: "2020-01-01"), today: "2026-11-14", context: context
            )
            let other = ModelContext(container)
            let saved = try #require(other.fetch(FetchDescriptor<ItemPeriod>()).first)
            try PeriodOperations.correct(
                saved,
                input: .init(
                    start: "2020-02-01", end: alreadyEnded ? "2026-11-12" : nil, isOngoing: !alreadyEnded
                ),
                today: "2026-11-14",
                context: other
            )
            #expect(throws: RecordError.staleReview) {
                try PeriodOperations.end(period, on: "2026-11-14", today: "2026-11-14", context: context)
            }
            #expect(!context.hasChanges)
            return (period.uuid, period.createdAt)
        }
        let context = ModelContext(try StallyModelContainerFactory.disk(at: url))
        let saved = try #require(context.fetch(FetchDescriptor<ItemPeriod>()).first)
        #expect(saved.uuid == identity.0 && saved.createdAt == identity.1)
        #expect(saved.startLocalDate == "2020-02-01")
        #expect(saved.endLocalDate == (alreadyEnded ? "2026-11-12" : nil))
        #expect(saved.isOngoing == !alreadyEnded)
        if !alreadyEnded {
            try PeriodOperations.end(saved, on: "2026-11-14", today: "2026-11-14", context: context)
            #expect(saved.startLocalDate == "2020-02-01")
            #expect(saved.endLocalDate == "2026-11-14" && !saved.isOngoing)
        }
    }

    @Test(arguments: [false, true])
    func endingRejectsMissingOrAmbiguousSavedIdentity(duplicate: Bool) throws {
        let container = try StallyModelContainerFactory.inMemory()
        let context = container.mainContext
        context.autosaveEnabled = false
        let item = try ItemOperations.create(context: context, name: "History")
        let period = try PeriodOperations.add(
            to: item, input: .init(start: "2020"), today: "2026-11-14", context: context
        )
        let other = ModelContext(container)
        let saved = try #require(other.fetch(FetchDescriptor<ItemPeriod>()).first)
        if duplicate {
            let parent = try #require(saved.item)
            let additional = ItemPeriod(item: parent, startLocalDate: "2021", endLocalDate: nil, isOngoing: true)
            additional.uuid = period.uuid
            other.insert(additional)
        } else {
            other.delete(saved)
        }
        try other.save()
        #expect(throws: duplicate ? RecordError.ambiguousIdentity : RecordError.missingRecord) {
            try PeriodOperations.end(period, on: nil, today: "2026-11-14", context: context)
        }
        #expect(!context.hasChanges)
        let periods = try ModelContext(container).fetch(FetchDescriptor<ItemPeriod>())
        #expect(periods.count == (duplicate ? 2 : 0))
        let allAreOngoing = periods.allSatisfy(\.isOngoing)
        #expect(allAreOngoing)
    }

    @Test
    func endingAfterUnrelatedWritesUpdatesTheObservedPeriodImmediately() throws {
        let container = try StallyModelContainerFactory.inMemory()
        let context = container.mainContext
        context.autosaveEnabled = false
        let item = try ItemOperations.create(context: context, name: "History")
        let period = try PeriodOperations.add(
            to: item, input: .init(start: "2020"), today: "2026-11-14", context: context
        )
        let other = ModelContext(container)
        let parent = try ItemOperations.item(context: other, uuid: item.uuid)
        try MarkOperations.add(to: parent, localDateTime: "2026-11-14", context: other)
        try PeriodOperations.end(period, on: "2026-11", today: "2026-11-14", context: context)
        #expect(period.startLocalDate == "2020")
        #expect(period.endLocalDate == "2026-11" && !period.isOngoing)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<ItemMark>()) == 1)
        #expect(throws: RecordError.periodAlreadyEnded) {
            try PeriodOperations.end(period, on: nil, today: "2026-11-14", context: context)
        }
    }
}
