import Foundation
import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct PeriodStartingTests {
    @Test(arguments: [false, true], [false, true])
    func startingRejectsSavedSiblingConflictsAfterReopen(resuming: Bool, ongoing: Bool) throws {
        let directory = PersistentTestDirectory.makeURL()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: "period-starting.store")
        let identities = try autoreleasepool {
            let container = try StallyModelContainerFactory.disk(at: url)
            let context = container.mainContext
            context.autosaveEnabled = false
            let item = try ItemOperations.create(context: context, name: "History")
            let previous = try PeriodOperations.add(
                to: item,
                input: .init(start: "2010", end: "2011", isOngoing: false),
                today: "2026-11-14",
                context: context
            )
            _ = item.periods
            let other = ModelContext(container)
            let parent = try ItemOperations.item(context: other, uuid: item.uuid)
            let sibling = try PeriodOperations.add(
                to: parent,
                input: .init(start: "2020", end: ongoing ? nil : "2022", isOngoing: ongoing),
                today: "2026-11-14",
                context: other
            )
            #expect(throws: ongoing ? RecordError.ongoingPeriodExists : RecordError.overlappingPeriods) {
                if resuming {
                    try PeriodOperations.resume(previous, on: "2021", today: "2026-11-14", context: context)
                } else {
                    try PeriodOperations.add(
                        to: item, input: .init(start: "2021"), today: "2026-11-14", context: context
                    )
                }
            }
            #expect(!context.hasChanges)
            return Set([previous.uuid, sibling.uuid])
        }
        let context = ModelContext(try StallyModelContainerFactory.disk(at: url))
        let periods = try context.fetch(FetchDescriptor<ItemPeriod>())
        #expect(Set(periods.map(\.uuid)) == identities)
        #expect(Set(periods.compactMap(\.startLocalDate)) == ["2010", "2020"])
        #expect(periods.filter(\.isOngoing).count == (ongoing ? 1 : 0))
    }

    @Test(arguments: [false, true])
    func additionRejectsMissingOrAmbiguousSavedOwner(duplicate: Bool) throws {
        let container = try StallyModelContainerFactory.inMemory()
        let context = container.mainContext
        context.autosaveEnabled = false
        let item = try ItemOperations.create(context: context, name: "History")
        _ = item.periods
        let other = ModelContext(container)
        let saved = try ItemOperations.item(context: other, uuid: item.uuid)
        if duplicate {
            let additional = Item(name: "Same identity", note: nil)
            additional.uuid = item.uuid
            other.insert(additional)
        } else {
            other.delete(saved)
        }
        try other.save()
        #expect(throws: duplicate ? RecordError.ambiguousIdentity : RecordError.missingRecord) {
            try PeriodOperations.add(to: item, input: .init(), today: "2026-11-14", context: context)
        }
        #expect(!context.hasChanges)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<ItemPeriod>()) == 0)
    }

    @Test(arguments: [false, true])
    func resumptionRejectsMissingOrAmbiguousSavedPeriod(duplicate: Bool) throws {
        let container = try StallyModelContainerFactory.inMemory()
        let context = container.mainContext
        context.autosaveEnabled = false
        let item = try ItemOperations.create(context: context, name: "History")
        let previous = try PeriodOperations.add(
            to: item,
            input: .init(start: "2020", end: "2021", isOngoing: false),
            today: "2026-11-14",
            context: context
        )
        let other = ModelContext(container)
        let saved = try #require(other.fetch(FetchDescriptor<ItemPeriod>()).first)
        if duplicate {
            let parent = try #require(saved.item)
            let additional = ItemPeriod(item: parent, startLocalDate: "2022", endLocalDate: "2023", isOngoing: false)
            additional.uuid = previous.uuid
            other.insert(additional)
        } else {
            other.delete(saved)
        }
        try other.save()
        #expect(throws: duplicate ? RecordError.ambiguousIdentity : RecordError.missingRecord) {
            try PeriodOperations.resume(previous, on: "2024", today: "2026-11-14", context: context)
        }
        #expect(!context.hasChanges)
        let periods = try ModelContext(container).fetch(FetchDescriptor<ItemPeriod>())
        #expect(periods.count == (duplicate ? 2 : 0))
        let hasOngoingPeriod = periods.contains(where: \.isOngoing)
        #expect(!hasOngoingPeriod)
    }

    @Test
    func resumptionRejectsAnInterveningReopening() throws {
        let container = try StallyModelContainerFactory.inMemory()
        let context = container.mainContext
        context.autosaveEnabled = false
        let item = try ItemOperations.create(context: context, name: "History")
        let previous = try PeriodOperations.add(
            to: item,
            input: .init(start: "2020", end: "2021", isOngoing: false),
            today: "2026-11-14",
            context: context
        )
        let other = ModelContext(container)
        let saved = try #require(other.fetch(FetchDescriptor<ItemPeriod>()).first)
        try PeriodOperations.correct(saved, input: .init(start: "2020"), today: "2026-11-14", context: other)
        #expect(throws: RecordError.invalidPeriod) {
            try PeriodOperations.resume(previous, on: "2024", today: "2026-11-14", context: context)
        }
        #expect(!context.hasChanges)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<ItemPeriod>()) == 1)
    }

    @Test(arguments: [false, true])
    func startingAfterUnrelatedWritesUpdatesTheObservedItem(resuming: Bool) throws {
        let container = try StallyModelContainerFactory.inMemory()
        let context = container.mainContext
        context.autosaveEnabled = false
        let item = try ItemOperations.create(context: context, name: "History")
        let previous = try PeriodOperations.add(
            to: item,
            input: .init(start: "2020", end: "2021", isOngoing: false),
            today: "2026-11-14",
            context: context
        )
        let other = ModelContext(container)
        let parent = try ItemOperations.item(context: other, uuid: item.uuid)
        try MarkOperations.add(to: parent, localDateTime: "2026-11-14", context: other)
        let started: ItemPeriod
        if resuming {
            started = try PeriodOperations.resume(previous, on: "2022", today: "2026-11-14", context: context)
        } else {
            started = try PeriodOperations.add(
                to: item, input: .init(start: "2022"), today: "2026-11-14", context: context
            )
        }
        #expect(started.modelContext === context && started.item === item)
        #expect(started.uuid != previous.uuid && started.isOngoing)
        #expect(previous.endLocalDate == "2021" && !previous.isOngoing)
        #expect(Set((item.periods ?? []).map(\.uuid)) == [previous.uuid, started.uuid])
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<ItemMark>()) == 1)
    }
}
