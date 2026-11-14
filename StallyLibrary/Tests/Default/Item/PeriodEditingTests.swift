import Foundation
import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct PeriodEditingTests {
    @Test
    func staleEditorCannotReopenAnInterveningEndAfterReopen() throws {
        let directory = PersistentTestDirectory.makeURL()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: "period-edit.store")
        let identity = try autoreleasepool {
            let container = try StallyModelContainerFactory.disk(at: url)
            let context = container.mainContext
            context.autosaveEnabled = false
            let item = try ItemOperations.create(context: context, name: "History")
            let original = PeriodInput(start: "2020-01-01")
            let period = try PeriodOperations.add(
                to: item, input: original, today: "2026-11-13", context: context
            )
            let other = ModelContext(container)
            let saved = try #require(other.fetch(FetchDescriptor<ItemPeriod>()).first)
            try PeriodOperations.end(saved, on: "2026-11-12", today: "2026-11-13", context: other)
            #expect(throws: RecordError.staleReview) {
                try PeriodOperations.correct(
                    period,
                    input: .init(start: "2020-02-01"),
                    today: "2026-11-13",
                    context: context,
                    original: original
                )
            }
            #expect(!context.hasChanges)
            return period.uuid
        }
        let context = ModelContext(try StallyModelContainerFactory.disk(at: url))
        let saved = try #require(context.fetch(FetchDescriptor<ItemPeriod>()).first)
        #expect(saved.uuid == identity)
        #expect(saved.startLocalDate == "2020-01-01")
        #expect(saved.endLocalDate == "2026-11-12" && !saved.isOngoing)
    }

    @Test(arguments: [
        PeriodInput(start: "2020-02", end: "2021", isOngoing: false),
        PeriodInput(start: "2020", end: "2021-02", isOngoing: false),
        PeriodInput(start: "2020")
    ])
    func staleEditorRejectsChangesToAnyPeriodField(_ revised: PeriodInput) throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let item = try ItemOperations.create(context: context, name: "History")
        let original = PeriodInput(start: "2020", end: "2021", isOngoing: false)
        let period = try PeriodOperations.add(
            to: item, input: original, today: "2026-11-13", context: context
        )
        try PeriodOperations.correct(period, input: revised, today: "2026-11-13", context: context)
        #expect(throws: RecordError.staleReview) {
            try PeriodOperations.correct(
                period, input: original, today: "2026-11-13", context: context, original: original
            )
        }
        #expect(period.startLocalDate == revised.start)
        #expect(period.endLocalDate == revised.end)
        #expect(period.isOngoing == revised.isOngoing)
        #expect(!context.hasChanges)
    }

    @Test
    func currentEditorCanCorrectAfterUnrelatedWritesAndExplicitlyReopen() throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let item = try ItemOperations.create(context: context, name: "History")
        let original = PeriodInput(start: "2020", end: "2021", isOngoing: false)
        let period = try PeriodOperations.add(
            to: item, input: original, today: "2026-11-13", context: context
        )
        let identity = period.uuid
        let registered = period.createdAt
        try MarkOperations.add(to: item, localDateTime: "2026-11-13", context: context)
        let corrected = PeriodInput(start: "2020-02", end: "2021", isOngoing: false)
        try PeriodOperations.correct(
            period, input: corrected, today: "2026-11-13", context: context, original: original
        )
        #expect(period.startLocalDate == "2020-02")
        #expect(period.endLocalDate == "2021" && !period.isOngoing)
        let correctedPeriod = try #require(
            ModelContext(context.container).fetch(FetchDescriptor<ItemPeriod>()).first
        )
        #expect(correctedPeriod.startLocalDate == "2020-02")
        #expect(correctedPeriod.endLocalDate == "2021" && !correctedPeriod.isOngoing)
        try PeriodOperations.correct(
            period,
            input: .init(start: "2020-02"),
            today: "2026-11-13",
            context: context,
            original: corrected
        )
        #expect(period.isOngoing && period.endLocalDate == nil)
        let reopenedPeriod = try #require(
            ModelContext(context.container).fetch(FetchDescriptor<ItemPeriod>()).first
        )
        #expect(reopenedPeriod.isOngoing && reopenedPeriod.endLocalDate == nil)
        #expect(reopenedPeriod.uuid == identity && reopenedPeriod.createdAt == registered)
        #expect(item.marks?.count == 1)
    }

    @Test(arguments: [false, true])
    func reviewedEditorRejectsMissingOrAmbiguousSavedIdentity(duplicate: Bool) throws {
        let container = try StallyModelContainerFactory.inMemory()
        let context = container.mainContext
        context.autosaveEnabled = false
        let item = try ItemOperations.create(context: context, name: "History")
        let original = PeriodInput(start: "2020")
        let period = try PeriodOperations.add(
            to: item, input: original, today: "2026-11-14", context: context
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
            try PeriodOperations.correct(
                period, input: .init(start: "2020-02"), today: "2026-11-14", context: context, original: original
            )
        }
        let savedPeriods = try ModelContext(container).fetch(FetchDescriptor<ItemPeriod>())
        #expect(savedPeriods.count == (duplicate ? 2 : 0))
        #expect(!savedPeriods.contains { $0.startLocalDate == "2020-02" })
        #expect(!context.hasChanges)
    }

    @Test
    func reviewedEditorValidatesPeriodsSavedByAnotherContext() throws {
        let container = try StallyModelContainerFactory.inMemory()
        let context = container.mainContext
        context.autosaveEnabled = false
        let item = try ItemOperations.create(context: context, name: "History")
        let original = PeriodInput(start: "2020-05", end: "2020-06", isOngoing: false)
        let period = try PeriodOperations.add(
            to: item, input: original, today: "2026-11-14", context: context
        )
        _ = item.periods
        let other = ModelContext(container)
        let parent = try ItemOperations.item(context: other, uuid: item.uuid)
        try PeriodOperations.add(
            to: parent,
            input: .init(start: "2020-01", end: "2020-04", isOngoing: false),
            today: "2026-11-14",
            context: other
        )
        #expect(throws: RecordError.overlappingPeriods) {
            try PeriodOperations.correct(
                period,
                input: .init(start: "2020-03", end: "2020-06", isOngoing: false),
                today: "2026-11-14",
                context: context,
                original: original
            )
        }
        let savedPeriods = try ModelContext(container).fetch(FetchDescriptor<ItemPeriod>())
        #expect(Set(savedPeriods.compactMap(\.startLocalDate)) == ["2020-01", "2020-05"])
        #expect(!context.hasChanges)
    }
}
