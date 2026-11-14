import Foundation
import SwiftData

extension TransferOperations {
    /// Reviews identity matches; this step does not create or modify any database object.
    public static func review(_ archive: TransferArchive, context: ModelContext) throws -> TransferReview {
        try RecordMutation.validate(context, models: [])
        let baseline = try snapshot(context: ModelContext(context.container), includingImages: true)
        return try makeReview(archive, baseline: baseline)
    }

    /// Prepares values without blocking the UI; apply still checks the account and current library.
    public static func prepareReview(_ archive: TransferArchive, context: ModelContext) async throws -> TransferReview {
        try RecordMutation.validate(context, models: [])
        let review = try await TransferPreparation.prepareReview(archive, container: context.container)
        try Task.checkCancellation()
        try RecordMutation.validate(context, models: [])
        return review
    }

    nonisolated internal static func makeReview(_ archive: TransferArchive, baseline: TransferArchive) throws
    -> TransferReview {
        try TransferBudget.current.check(recordCount: archive.manifest.recordCount + baseline.manifest.recordCount)
        try validateIdentities(incoming: archive.manifest, local: baseline.manifest)
        return .init(
            rows: TransferReviewRows.rows(archive.manifest, local: baseline.manifest),
            incoming: archive,
            baseline: baseline
        )
    }

    /// Revalidates the reviewed snapshot and selected graph, then commits once in an owned context.
    @discardableResult
    public static func apply(_ review: TransferReview, selection: Set<UUID>, today: String, context: ModelContext)
    throws
    -> Int {
        try RecordMutation.validate(context, models: [])
        try TransferCapacity.check(review.incoming, context: context)
        let writer = ModelContext(context.container)
        writer.autosaveEnabled = false
        let current = try snapshot(context: writer, includingImages: true, stagingImages: false)
        var expected = review.baseline.manifest
        expected.exportedAt = current.manifest.exportedAt
        guard expected == current.manifest else { throw TransferError.staleReview }
        let candidates = Set(review.rows.lazy.filter { !$0.isUnchanged }.map(\.id))
        guard selection.isSubset(of: Set(review.rows.lazy.map(\.id))) else { throw TransferError.invalidSelection }
        let changes = selection.intersection(candidates)
        guard !changes.isEmpty else {
            return 0
        }
        do {
            try TransferImportMutation.apply(review.incoming, selection: changes, today: today, context: writer)
            try Task.checkCancellation()
            try writer.save()
        } catch {
            writer.rollback()
            throw error
        }
        return changes.count
    }
}

private extension TransferOperations {
    nonisolated static func validateIdentities(incoming: TransferManifest, local: TransferManifest) throws {
        let incomingKinds = TransferReviewRows.kinds(incoming)
        let localKinds = TransferReviewRows.kinds(local)
        for (uuid, kind) in incomingKinds {
            if let existing = localKinds[uuid], existing != kind { throw TransferError.incompleteGraph }
        }
        let incomingParents = TransferReviewRows.parents(incoming)
        let localParents = TransferReviewRows.parents(local)
        for (uuid, parent) in incomingParents {
            if let existing = localParents[uuid], existing != parent { throw TransferError.incompleteGraph }
        }
    }
}
