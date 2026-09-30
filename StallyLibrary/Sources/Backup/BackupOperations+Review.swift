import Foundation
import SwiftData

public extension BackupOperations {
    /// Captures a read-only review, including metadata that aggregate counts cannot detect.
    static func review(
        data: Data,
        currentItems: [Item],
        replacingExistingItems: Bool = false
    ) -> BackupImportReview {
        .init(
            data: data,
            currentItems: snapshot(for: currentItems).items.sorted { $0.id.uuidString < $1.id.uuidString },
            replacingExistingItems: replacingExistingItems,
            preview: preview(data: data, currentItems: currentItems, replacingExistingItems: replacingExistingItems)
        )
    }

    /// Applies the exact reviewed payload and method, or requests a fresh review without mutation.
    @discardableResult
    static func importReviewed(_ review: BackupImportReview, context: ModelContext) throws -> BackupImportResult {
        let currentItems = try ItemOperations.items(context: context)
        let refreshedReview = self.review(
            data: review.data,
            currentItems: currentItems,
            replacingExistingItems: review.replacingExistingItems
        )
        guard refreshedReview == review else {
            throw BackupError.reviewChanged(refreshedReview)
        }
        if review.replacingExistingItems {
            return try replaceLibrary(data: review.data, context: context)
        }
        return try mergeIntoLibrary(data: review.data, context: context)
    }
}
