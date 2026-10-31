import Foundation
import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct TransferTests {
    @Test
    func packageRoundTripIsIdentityPreservingAndReplayDoesNotWrite() async throws {
        let source = ModelContext(try StallyModelContainerFactory.inMemory())
        let item = try ItemOperations.create(context: source, name: "Exact Name", note: "Context")
        try ItemOperations.setArchived(item, to: true, context: source)
        try MarkOperations.add(to: item, localDateTime: "2024-01-01", context: source)
        try MarkOperations.add(to: item, localDateTime: "2024-01-01", context: source)
        try TagOperations.create(name: "Unused", context: source)
        let archive = try TransferOperations.export(context: source, includingImages: true)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".stally")
        defer { try? FileManager.default.removeItem(at: url) }
        try archive.fileWrapper().write(to: url, options: .atomic, originalContentsURL: nil)
        let loaded = try await TransferFileOperations.read(url)
        let target = ModelContext(try StallyModelContainerFactory.inMemory())
        let review = try TransferOperations.review(loaded, context: target)
        #expect(review.defaultSelection.count == 4)
        #expect(
            try TransferOperations.apply(
                review,
                selection: review.defaultSelection,
                today: "2026-10-31",
                context: target
            ) == 4
        )
        let copy = try ItemOperations.item(context: target, uuid: item.uuid)
        #expect(copy.isArchived && copy.marks?.count == 2)
        #expect(try target.fetchCount(FetchDescriptor<StallyLibrary.Tag>()) == 1)
        let replay = try TransferOperations.review(loaded, context: target)
        let replayMatches = replay.rows.allSatisfy(\.isUnchanged)
        #expect(replayMatches)
        #expect(
            try TransferOperations.apply(
                replay,
                selection: Set(replay.rows.map(\.id)),
                today: "2026-10-31",
                context: target
            ) == 0
        )
        #expect(!target.hasChanges)
    }

    @Test
    func conflictsKeepCurrentAndStaleReviewRejectsAllChanges() throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let item = try ItemOperations.create(context: context, name: "Original")
        let archive = try TransferOperations.export(context: context, includingImages: false)
        try ItemOperations.update(item, name: "Local", note: "", context: context)
        let review = try TransferOperations.review(archive, context: context)
        #expect(review.defaultSelection.isEmpty)
        #expect(!review.rows[0].isUnchanged)
        try ItemOperations.update(item, name: "Later", note: "", context: context)
        #expect(throws: TransferError.self) {
            try TransferOperations.apply(review, selection: [item.uuid], today: "2026-10-31", context: context)
        }
        #expect(item.name == "Later")
    }

    @Test
    func excludingRequiredParentRejectsWithoutLeakingNewTag() throws {
        let source = ModelContext(try StallyModelContainerFactory.inMemory())
        let item = try ItemOperations.create(context: source, name: "Parent")
        let mark = try MarkOperations.add(to: item, localDateTime: "2024-01-01", context: source)
        let tag = try TagOperations.create(name: "Not leaked", context: source)
        let archive = try TransferOperations.export(context: source, includingImages: false)
        let target = ModelContext(try StallyModelContainerFactory.inMemory())
        let review = try TransferOperations.review(archive, context: target)
        #expect(throws: TransferError.self) {
            try TransferOperations.apply(review, selection: [mark.uuid, tag.uuid], today: "2026-10-31", context: target)
        }
        #expect(try target.fetchCount(FetchDescriptor<StallyLibrary.Tag>()) == 0)
        #expect(try ModelContext(target.container).fetchCount(FetchDescriptor<ItemMark>()) == 0)
        #expect(!target.hasChanges)
    }

    @Test
    func missingNullableKeysAndFutureVersionsAreRejected() throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        try ItemOperations.create(context: context, name: "Nullable")
        let archive = try TransferOperations.export(context: context, includingImages: false)
        let data = try TransferCodec.encode(archive.manifest)
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        var items = try #require(object["items"] as? [[String: Any]])
        #expect(items[0]["representativeURL"] is NSNull)
        items[0].removeValue(forKey: "representativeURL")
        object["items"] = items
        #expect(throws: TransferError.self) { try TransferCodec.decode(JSONSerialization.data(withJSONObject: object)) }
        object["formatVersion"] = 2
        #expect(throws: TransferError.self) { try TransferCodec.decode(JSONSerialization.data(withJSONObject: object)) }
    }

    @Test
    func importedLinksRemainEditableWithoutImplicitURLRepair() async throws {
        let source = ModelContext(try StallyModelContainerFactory.inMemory())
        try ItemOperations.create(context: source, name: "Linked")
        let archive = try TransferOperations.export(context: source, includingImages: false)
        var manifest = archive.manifest
        for invalid in ["https://example.com/a b", "https://example.com/%GG", " https://example.com", ""] {
            manifest.items[0].representativeURL = invalid
            let data = try TransferCodec.encode(manifest)
            await #expect(throws: RecordError.invalidURL) {
                try await TransferFileOperations.readRecords(data)
            }
        }
        let link = "https://example.com/a%20b"
        manifest.items[0].representativeURL = link
        let loaded = try await TransferFileOperations.readRecords(TransferCodec.encode(manifest))
        let target = ModelContext(try StallyModelContainerFactory.inMemory())
        let review = try TransferOperations.review(loaded, context: target)
        try TransferOperations.apply(review, selection: review.defaultSelection, today: "2026-10-31", context: target)
        let item = try ItemOperations.item(context: target, uuid: manifest.items[0].uuid)
        var draft = ItemOperations.draft(for: item)
        draft.note = "Edited after import"
        let saved = try ItemOperations.save(draft, context: target)
        #expect(saved.representativeURL == link)
        #expect(saved.note == "Edited after import")
    }

    @Test
    func registrationMillisecondsDoNotCreateFalseConflict() throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let item = try ItemOperations.create(context: context, name: "Precision")
        let original = item.createdAt
        let archive = try TransferOperations.export(context: context, includingImages: false)
        let review = try TransferOperations.review(archive, context: context)
        let reviewMatches = review.rows.allSatisfy(\.isUnchanged)
        #expect(reviewMatches)
        #expect(item.createdAt == original)
        #expect(throws: TransferError.self) { try TransferTimestamp.date("2024-02-30T00:00:00.000Z") }
    }
}
