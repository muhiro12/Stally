import Foundation
import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct TransferReviewMediaTests {
    @Test(arguments: [false, true])
    func omittedIncomingBytesStillHaveAnImmutableCurrentImage(background: Bool) async throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let bytes = try PhotoTestImages.imageData()
        var draft = ItemDraft(name: "Records only")
        draft.photos = [.init(prepared: try await PhotoOperations.prepare(data: bytes))]
        try ItemOperations.save(draft, context: context)
        let incoming = try TransferOperations.export(context: context, includingImages: false)
        let photo = try #require(incoming.manifest.itemPhotos.first)
        let review: TransferReview
        if background {
            review = try await TransferOperations.prepareReview(incoming, context: context)
        } else {
            review = try TransferOperations.review(incoming, context: context)
        }
        #expect(review.imageData(for: photo.uuid, fromFile: false) == bytes)
        #expect(review.imageData(for: photo.uuid, fromFile: true) == nil)
        let unchanged = review.rows.allSatisfy(\.isUnchanged)
        #expect(unchanged)
        #expect(try TransferOperations.apply(review, selection: [], today: "2026-11-14", context: context) == 0)
    }

    @Test(arguments: [false, true], [false, true])
    func reviewCopiesOnlyComparedPhotosAndStillDetectsEveryImageChange(
        background: Bool,
        changeComparedPhoto: Bool
    ) async throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let bytes = try PhotoTestImages.imageData()
        let replacement = try PhotoTestImages.imageData(orientation: 3)
        let prepared = try await PhotoOperations.prepare(data: bytes)
        var draft = ItemDraft(name: "Photo review")
        draft.photos = [.init(prepared: prepared, caption: "Compared"), .init(prepared: prepared, caption: "Other")]
        let item = try ItemOperations.save(draft, context: context)
        let photos = try #require(item.photos).sorted { $0.sortOrder < $1.sortOrder }
        let compared = photos[0]
        let unrelated = photos[1]
        var manifest = try TransferOperations.export(context: context, includingImages: true).manifest
        manifest.itemPhotos.removeAll { $0.uuid != compared.uuid }
        manifest.itemPhotos[0].caption = "From file"
        let path = try #require(manifest.itemPhotos[0].image.path)
        let incoming = TransferArchive(manifest: manifest, media: [path: bytes])
        let review: TransferReview
        if background {
            review = try await TransferOperations.prepareReview(incoming, context: context)
        } else {
            review = try TransferOperations.review(incoming, context: context)
        }
        #expect(review.imageData(for: compared.uuid, fromFile: false) == bytes)
        #expect(review.imageData(for: compared.uuid, fromFile: true) == bytes)
        let unrelatedImage = try #require(review.baseline.manifest.itemPhotos.first { $0.uuid == unrelated.uuid })
        #expect(unrelatedImage.image.sha256 == TransferMedia.digest(bytes))
        let unrelatedPath = try #require(unrelatedImage.image.path)
        #expect(throws: POSIXError(.ENOENT)) {
            try review.baseline.imageData(path: unrelatedPath)
        }
        let other = ModelContext(context.container)
        let changedUUID = changeComparedPhoto ? compared.uuid : unrelated.uuid
        let changed = try #require(other.fetch(FetchDescriptor<ItemPhoto>()).first { $0.uuid == changedUUID })
        changed.imageData = replacement
        try other.save()
        #expect(review.imageData(for: compared.uuid, fromFile: false) == bytes)
        #expect(throws: TransferError.staleReview) {
            try TransferOperations.apply(review, selection: [compared.uuid], today: "2026-11-14", context: context)
        }
        let saved = try ModelContext(context.container).fetch(FetchDescriptor<ItemPhoto>())
        #expect(saved.first { $0.uuid == compared.uuid }?.caption == "Compared")
        #expect(saved.first { $0.uuid == changedUUID }?.imageData == replacement)
        #expect(!context.hasChanges)
    }

    @Test(arguments: [false, true])
    func textOnlyImportStagesNoLocalPhotosAndPreservesThemAfterReopen(background: Bool) async throws {
        let directory = PersistentTestDirectory.makeURL()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: "review.store")
        let bytes = try PhotoTestImages.imageData()
        let prepared = try await PhotoOperations.prepare(data: bytes)
        let identity = try autoreleasepool {
            let context = ModelContext(try StallyModelContainerFactory.disk(at: url))
            var draft = ItemDraft(name: "Before")
            draft.photos = [.init(prepared: prepared)]
            return try ItemOperations.save(draft, context: context).uuid
        }
        let container = try StallyModelContainerFactory.disk(at: url)
        let context = ModelContext(container)
        var manifest = try TransferOperations.export(context: context, includingImages: false).manifest
        manifest.itemPhotos = []
        manifest.items[0].name = "After"
        let incoming = TransferArchive(manifest: manifest, media: [:])
        let review: TransferReview
        if background {
            review = try await TransferOperations.prepareReview(incoming, context: context)
        } else {
            review = try TransferOperations.review(incoming, context: context)
        }
        let photo = try #require(review.baseline.manifest.itemPhotos.first)
        #expect(photo.image.sha256 == TransferMedia.digest(bytes))
        let path = try #require(photo.image.path)
        #expect(throws: POSIXError(.ENOENT)) {
            try review.baseline.imageData(path: path)
        }
        #expect(try TransferOperations.apply(review, selection: [identity], today: "2026-11-14", context: context) == 1)
        let reopened = ModelContext(try StallyModelContainerFactory.disk(at: url))
        let item = try ItemOperations.item(context: reopened, uuid: identity)
        #expect(item.name == "After")
        #expect(item.photos?.first?.uuid == photo.uuid)
        #expect(item.photos?.first?.imageData == bytes)
    }
}
