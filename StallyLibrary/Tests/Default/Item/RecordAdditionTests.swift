import Foundation
import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct RecordAdditionTests {
    @Test(arguments: ["mark", "period", "resume"], [false, true])
    func additionPreservesSavedOwnerFactsAfterReopen(kind: String, separateContainer: Bool) throws {
        let url = try storeURL()
        let identity = try autoreleasepool {
            let container = try StallyModelContainerFactory.disk(at: url)
            let context = ModelContext(container)
            let item = try ItemOperations.create(context: context, name: "Original", note: "Original note")
            let previous = try PeriodOperations.add(
                to: item,
                input: .init(start: "2020", end: "2021", isOngoing: false),
                today: "2026-11-14",
                context: context
            )
            _ = item.marks
            _ = item.periods
            let other = ModelContext(separateContainer ? try StallyModelContainerFactory.disk(at: url) : container)
            let saved = try ItemOperations.item(context: other, uuid: item.uuid)
            try ItemOperations.update(saved, name: "Latest", note: "Latest note", context: other)
            try ItemOperations.setFavorite(saved, to: true, context: other)
            try ItemOperations.setArchived(saved, to: true, context: other)
            if kind == "mark" {
                try MarkOperations.add(to: item, localDateTime: "2026-11-14", context: context)
            } else if kind == "period" {
                try PeriodOperations.add(to: item, input: .init(start: "2022"), today: "2026-11-14", context: context)
            } else {
                try PeriodOperations.resume(previous, on: "2022", today: "2026-11-14", context: context)
            }
            #expect(!context.hasChanges)
            return item.uuid
        }
        let context = ModelContext(try StallyModelContainerFactory.disk(at: url))
        let item = try ItemOperations.item(context: context, uuid: identity)
        #expect(item.name == "Latest" && item.note == "Latest note")
        #expect(item.isFavorite && item.isArchived)
        #expect(item.marks?.count == (kind == "mark" ? 1 : 0))
        #expect(item.periods?.count == (kind == "mark" ? 1 : 2))
    }

    @Test(arguments: [false, true])
    func markAdditionUsesSavedRecordingChoice(separateContainer: Bool) throws {
        let url = try storeURL()
        let identity = try autoreleasepool {
            let container = try StallyModelContainerFactory.disk(at: url)
            let context = ModelContext(container)
            let item = try ItemOperations.create(context: context, name: "History")
            let other = ModelContext(separateContainer ? try StallyModelContainerFactory.disk(at: url) : container)
            let saved = try ItemOperations.item(context: other, uuid: item.uuid)
            try ItemOperations.setMarkRecordingEnabled(saved, to: false, context: other)
            #expect(throws: RecordError.recordingPaused) {
                try MarkOperations.add(to: item, localDateTime: "2026-11-14", context: context)
            }
            #expect(!context.hasChanges)
            return item.uuid
        }
        let context = ModelContext(try StallyModelContainerFactory.disk(at: url))
        let item = try ItemOperations.item(context: context, uuid: identity)
        #expect(!item.isMarkRecordingEnabled)
        #expect(try context.fetchCount(FetchDescriptor<ItemMark>()) == 0)
    }

    @Test(arguments: [false, true])
    func markAdditionRejectsMissingOrAmbiguousSavedOwner(duplicate: Bool) throws {
        let container = try StallyModelContainerFactory.inMemory()
        let context = ModelContext(container)
        let item = try ItemOperations.create(context: context, name: "History")
        let other = ModelContext(container)
        if duplicate {
            let additional = Item(name: "Duplicate", note: nil)
            additional.uuid = item.uuid
            other.insert(additional)
        } else {
            other.delete(try ItemOperations.item(context: other, uuid: item.uuid))
        }
        try other.save()
        #expect(throws: duplicate ? RecordError.ambiguousIdentity : RecordError.missingRecord) {
            try MarkOperations.add(to: item, localDateTime: "2026-11-14", context: context)
        }
        #expect(!context.hasChanges)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<ItemMark>()) == 0)
    }

    private func storeURL() throws -> URL {
        let directory = PersistentTestDirectory.makeURL()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appending(path: "record-addition.store")
    }
}
