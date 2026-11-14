import Foundation
import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct SaveFailureTests {
    @Test
    func failedReviewedPeriodSavePreservesTheReopenedRecord() throws {
        let directory = PersistentTestDirectory.makeURL()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: "period.store")
        let original = PeriodInput(start: "2020", end: "2021", isOngoing: false)
        let identity = try autoreleasepool {
            let context = ModelContext(try StallyModelContainerFactory.disk(at: url))
            let item = try ItemOperations.create(context: context, name: "History")
            return try PeriodOperations.add(
                to: item, input: original, today: "2026-11-14", context: context
            ).uuid
        }
        try autoreleasepool {
            let schema = StallyModelContainerFactory.schema
            let configuration = ModelConfiguration(
                "Read Only", schema: schema, url: url, allowsSave: false, cloudKitDatabase: .none
            )
            let context = ModelContext(try ModelContainer(for: schema, configurations: [configuration]))
            let period = try #require(context.fetch(FetchDescriptor<ItemPeriod>()).first)
            #expect(throws: (any Error).self) {
                try PeriodOperations.correct(
                    period, input: .init(start: "2020-02"), today: "2026-11-14", context: context, original: original
                )
            }
            #expect(period.startLocalDate == original.start)
            #expect(period.endLocalDate == original.end && !period.isOngoing)
            #expect(!context.hasChanges)
        }
        let context = ModelContext(try StallyModelContainerFactory.disk(at: url))
        let saved = try #require(context.fetch(FetchDescriptor<ItemPeriod>()).first)
        #expect(saved.uuid == identity)
        #expect(saved.startLocalDate == original.start)
        #expect(saved.endLocalDate == original.end && !saved.isOngoing)
    }

    @Test
    func failedSaveRollsBackOnlyTheAttemptedOperation() throws {
        let directory = PersistentTestDirectory.makeURL()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: "readonly.store")
        let identity = try autoreleasepool {
            let container = try StallyModelContainerFactory.disk(at: url)
            let context = ModelContext(container)
            return try ItemOperations.create(context: context, name: "Original").uuid
        }
        try autoreleasepool {
            let schema = StallyModelContainerFactory.schema
            let configuration = ModelConfiguration(
                "Stally",
                schema: schema,
                url: url,
                allowsSave: false,
                cloudKitDatabase: .none
            )
            let container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
            let context = ModelContext(container)
            context.autosaveEnabled = false
            let item = try ItemOperations.item(context: context, uuid: identity)
            #expect(throws: (any Error).self) {
                try ItemOperations.update(item, name: "Rejected", note: "Rejected", context: context)
            }
            #expect(item.name == "Original" && item.note == nil)
            #expect(!context.hasChanges)
        }
        let reopened = try StallyModelContainerFactory.disk(at: url)
        let context = ModelContext(reopened)
        #expect(try ItemOperations.item(context: context, uuid: identity).name == "Original")
    }

    @Test
    func foreignContextAndDuplicateIdentityNeverChooseAnotherRecord() throws {
        let container = try StallyModelContainerFactory.inMemory()
        let context = ModelContext(container)
        let otherContext = ModelContext(container)
        let first = try ItemOperations.create(context: context, name: "Same")
        #expect(throws: RecordError.wrongContext) {
            try ItemOperations.setFavorite(first, to: true, context: otherContext)
        }
        #expect(!first.isFavorite)
        let second = try ItemOperations.create(context: context, name: "Same")
        second.uuid = first.uuid
        try context.save()
        #expect(throws: RecordError.ambiguousIdentity) {
            try ItemOperations.item(context: context, uuid: first.uuid)
        }
        #expect(try context.fetchCount(FetchDescriptor<Item>()) == 2)
    }
}
