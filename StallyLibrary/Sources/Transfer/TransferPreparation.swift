import Foundation
import SwiftData

/// Only immutable values cross back to the main actor; models remain on this executor.
@ModelActor
actor TransferPreparation {
    @concurrent
    static func export(container: ModelContainer, includingImages: Bool) async throws -> TransferArchive {
        let worker = TransferPreparation(modelContainer: container)
        return try await worker.snapshot(includingImages: includingImages)
    }

    @concurrent
    static func prepareReview(_ archive: TransferArchive, container: ModelContainer) async throws -> TransferReview {
        let worker = TransferPreparation(modelContainer: container)
        return try await worker.review(archive)
    }

    func snapshot(includingImages: Bool) throws -> TransferArchive {
        let archive = try TransferOperations.snapshot(
            context: ModelContext(modelContainer),
            includingImages: includingImages
        )
        let current = try TransferOperations.snapshot(
            context: ModelContext(modelContainer),
            includingImages: includingImages,
            stagingImages: false
        )
        var expected = archive.manifest
        expected.exportedAt = current.manifest.exportedAt
        guard expected == current.manifest else { throw TransferError.changedDuringPreparation }
        return archive
    }

    func review(_ archive: TransferArchive) throws -> TransferReview {
        let baseline = try snapshot(includingImages: true)
        return try TransferOperations.makeReview(archive, baseline: baseline)
    }
}
