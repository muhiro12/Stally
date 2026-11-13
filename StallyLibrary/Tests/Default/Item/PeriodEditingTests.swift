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
            let context = ModelContext(try StallyModelContainerFactory.disk(at: url))
            let item = try ItemOperations.create(context: context, name: "History")
            let original = PeriodInput(start: "2020-01-01")
            let period = try PeriodOperations.add(
                to: item, input: original, today: "2026-11-13", context: context
            )
            try PeriodOperations.end(period, on: "2026-11-12", today: "2026-11-13", context: context)
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
        try PeriodOperations.correct(
            period,
            input: .init(start: "2020-02"),
            today: "2026-11-13",
            context: context,
            original: corrected
        )
        #expect(period.isOngoing && period.endLocalDate == nil)
        #expect(period.uuid == identity && period.createdAt == registered)
        #expect(item.marks?.count == 1)
    }
}
