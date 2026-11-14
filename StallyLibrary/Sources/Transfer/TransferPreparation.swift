import Foundation
import SwiftData

/// Only immutable values cross back to the main actor; models remain on this executor.
@ModelActor
actor TransferPreparation {
    @concurrent
    static func export(container: ModelContainer, includingImages: Bool) async throws -> TransferArchive {
        let worker = TransferPreparation(modelContainer: container)
        return try await worker.snapshot(includingImages: includingImages, stagingScope: .all)
    }

    @concurrent
    static func prepareReview(_ archive: TransferArchive, container: ModelContainer) async throws -> TransferReview {
        let worker = TransferPreparation(modelContainer: container)
        return try await worker.review(archive)
    }

    func snapshot(includingImages: Bool, stagingScope: TransferStaging.Scope) throws -> TransferArchive {
        let archive = try TransferOperations.snapshot(
            context: ModelContext(modelContainer),
            includingImages: includingImages,
            stagingScope: stagingScope
        )
        let current = try TransferOperations.snapshot(
            context: ModelContext(modelContainer),
            includingImages: includingImages,
            stagingScope: .noCopies
        )
        var expected = archive.manifest
        expected.exportedAt = current.manifest.exportedAt
        guard expected == current.manifest else { throw TransferError.changedDuringPreparation }
        return archive
    }

    func review(_ archive: TransferArchive) throws -> TransferReview {
        let baseline = try snapshot(
            includingImages: true,
            stagingScope: .photos(Set(archive.manifest.itemPhotos.map(\.uuid)))
        )
        return try TransferOperations.makeReview(archive, baseline: baseline)
    }
}
