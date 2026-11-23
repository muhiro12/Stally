import Foundation
import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct MarkEditingTests {
    @Test(arguments: [false, true], ["2026-11-10", "2026-11-11"])
    func staleEditorPreservesSavedDateAfterReopen(separateContainer: Bool, submitted: String) throws {
        let url = try storeURL()
        let identity = try autoreleasepool {
            let container = try StallyModelContainerFactory.disk(at: url)
            let context = ModelContext(container)
            let item = try ItemOperations.create(context: context, name: "History")
            let mark = try MarkOperations.add(to: item, localDateTime: "2026-11-10", context: context)
            let original = mark.localDateTime
            let other = ModelContext(separateContainer ? try StallyModelContainerFactory.disk(at: url) : container)
            let saved = try #require(other.fetch(FetchDescriptor<ItemMark>()).first)
            try MarkOperations.correct(saved, localDateTime: "2026-11-12T10:30", context: other)
            #expect(throws: RecordError.staleReview) {
                try MarkOperations.correct(mark, localDateTime: submitted, context: context, original: original)
            }
            #expect(!context.hasChanges)
            return (mark.uuid, mark.createdAt, item.uuid)
        }
        let context = ModelContext(try StallyModelContainerFactory.disk(at: url))
        let saved = try #require(context.fetch(FetchDescriptor<ItemMark>()).first)
        #expect(saved.uuid == identity.0 && saved.createdAt == identity.1)
        #expect(saved.item?.uuid == identity.2)
        #expect(saved.localDateTime == "2026-11-12T10:30")
    }

    @Test
    func currentEditorCanCorrectWhilePausedAfterUnrelatedWritesAndReopen() throws {
        let url = try storeURL()
        let identity = try autoreleasepool {
            let context = ModelContext(try StallyModelContainerFactory.disk(at: url))
            let item = try ItemOperations.create(context: context, name: "History")
            let mark = try MarkOperations.add(to: item, localDateTime: "2026-11-10", context: context)
            let original = mark.localDateTime
            let other = ModelContext(context.container)
            let parent = try ItemOperations.item(context: other, uuid: item.uuid)
            try MarkOperations.add(to: parent, localDateTime: "2026-11-14", context: other)
            try ItemOperations.setMarkRecordingEnabled(parent, to: false, context: other)
            try MarkOperations.correct(mark, localDateTime: "2026-11-10T12:34", context: context, original: original)
            #expect(mark.localDateTime == "2026-11-10T12:34")
            #expect(!context.hasChanges)
            return (item.uuid, mark.uuid, mark.createdAt)
        }
        let context = ModelContext(try StallyModelContainerFactory.disk(at: url))
        let item = try ItemOperations.item(context: context, uuid: identity.0)
        let mark = try #require(item.marks?.first { $0.uuid == identity.1 })
        #expect(mark.localDateTime == "2026-11-10T12:34" && mark.createdAt == identity.2)
        #expect(!item.isMarkRecordingEnabled && item.marks?.count == 2)
        try MarkOperations.correct(mark, localDateTime: "2026-11-11", context: context, original: mark.localDateTime)
        #expect(mark.localDateTime == "2026-11-11")
    }

    @Test
    func staleEditorRejectsSameContextPrecisionChanges() throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let item = try ItemOperations.create(context: context, name: "History")
        let mark = try MarkOperations.add(to: item, localDateTime: "2026-11-10", context: context)
        let original = mark.localDateTime
        try MarkOperations.correct(mark, localDateTime: "2026-11-10T00:00", context: context)
        #expect(throws: RecordError.staleReview) {
            try MarkOperations.correct(mark, localDateTime: original, context: context, original: original)
        }
        #expect(mark.localDateTime == "2026-11-10T00:00" && !context.hasChanges)
    }

    @Test(arguments: [false, true])
    func reviewedEditorRejectsMissingOrAmbiguousIdentity(duplicate: Bool) throws {
        let container = try StallyModelContainerFactory.inMemory()
        let context = ModelContext(container)
        let item = try ItemOperations.create(context: context, name: "History")
        let mark = try MarkOperations.add(to: item, localDateTime: "2026-11-10", context: context)
        let other = ModelContext(container)
        let saved = try #require(other.fetch(FetchDescriptor<ItemMark>()).first)
        if duplicate {
            let additional = ItemMark(item: try #require(saved.item), localDateTime: "2026-11-11")
            additional.uuid = mark.uuid
            other.insert(additional)
        } else {
            other.delete(saved)
        }
        try other.save()
        #expect(throws: duplicate ? RecordError.ambiguousIdentity : RecordError.missingRecord) {
            try MarkOperations.correct(mark, localDateTime: "2026-11-12", context: context, original: "2026-11-10")
        }
        let savedMarks = try ModelContext(container).fetch(FetchDescriptor<ItemMark>())
        #expect(savedMarks.count == (duplicate ? 2 : 0))
        #expect(!savedMarks.contains { $0.localDateTime == "2026-11-12" })
        #expect(!context.hasChanges)
    }

    private func storeURL() throws -> URL {
        let directory = PersistentTestDirectory.makeURL()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appending(path: "mark-edit.store")
    }
}
