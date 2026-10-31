import Foundation
import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct TransferMediaTests {
    @Test
    func photoBytesSurvivePackageImportAndRecordsOnlyNeverEraseThem() async throws {
        let source = ModelContext(try StallyModelContainerFactory.inMemory())
        let bytes = try PhotoTestImages.imageData()
        var draft = ItemDraft(name: "Photo")
        draft.photos = [.init(prepared: try await PhotoOperations.prepare(data: bytes), caption: "Original")]
        let item = try ItemOperations.save(draft, context: source)
        let archive = try TransferOperations.export(context: source, includingImages: true)
        let url = try await TransferFileOperations.writeTemporary(archive)
        defer { try? FileManager.default.removeItem(at: url) }
        let loaded = try await TransferFileOperations.read(url)
        let target = ModelContext(try StallyModelContainerFactory.inMemory())
        let review = try TransferOperations.review(loaded, context: target)
        try TransferOperations.apply(review, selection: review.defaultSelection, today: "2026-10-31", context: target)
        let restored = try ItemOperations.item(context: target, uuid: item.uuid)
        let photo = try #require(restored.photos?.first)
        #expect(photo.imageData == bytes)
        var edited = ItemOperations.draft(for: item)
        edited.photos[0].caption = "File Caption"
        try ItemOperations.save(edited, context: source)
        let recordsOnly = try TransferOperations.export(context: source, includingImages: false)
        let changes = try TransferOperations.review(recordsOnly, context: target)
        #expect(changes.defaultSelection.isEmpty)
        try TransferOperations.apply(changes, selection: [photo.uuid], today: "2026-10-31", context: target)
        let refreshed = try ModelContext(target.container).fetch(FetchDescriptor<ItemPhoto>())
        #expect(refreshed.first?.imageData == bytes)
        #expect(refreshed.first?.caption == "File Caption")
        let empty = ModelContext(try StallyModelContainerFactory.inMemory())
        let metadata = try TransferOperations.review(recordsOnly, context: empty)
        try TransferOperations.apply(
            metadata,
            selection: metadata.defaultSelection,
            today: "2026-10-31",
            context: empty
        )
        #expect(try empty.fetch(FetchDescriptor<ItemPhoto>()).first?.imageData == nil)
    }

    @Test
    func corruptMediaAndSymlinkedRecordsAreRejectedBeforeReview() async throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        var draft = ItemDraft(name: "Bounded")
        draft.photos = [.init(prepared: try await PhotoOperations.prepare(data: PhotoTestImages.imageData()))]
        try ItemOperations.save(draft, context: context)
        let archive = try TransferOperations.export(context: context, includingImages: true)
        let url = try await TransferFileOperations.writeTemporary(archive)
        defer { try? FileManager.default.removeItem(at: url) }
        let path = try #require(archive.manifest.itemPhotos.first?.image.path)
        try Data("corrupt".utf8).write(to: url.appendingPathComponent(path))
        await #expect(throws: (any Error).self) { try await TransferFileOperations.read(url) }
        let records = url.appendingPathComponent("records.json")
        let elsewhere = url.appendingPathComponent("original.json")
        try FileManager.default.moveItem(at: records, to: elsewhere)
        try FileManager.default.createSymbolicLink(at: records, withDestinationURL: elsewhere)
        await #expect(throws: (any Error).self) { try await TransferFileOperations.read(url) }
        let json = try TransferCodec.encode(archive.manifest)
        await #expect(throws: (any Error).self) { try await TransferFileOperations.readRecords(json) }
    }
}
