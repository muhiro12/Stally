import Foundation

/// Immutable input, method, and complete collection baseline for an import review.
public struct BackupImportReview: Equatable, Sendable {
    /// Validation and projected changes that the person reviews before importing.
    public let preview: BackupPreview
    /// Whether this review approves replacement rather than a preserving merge.
    public let replacingExistingItems: Bool

    /// The unchanged file bytes, for rebuilding the preview after a method change.
    public let data: Data
    let currentItems: [BackupItem]

    init(data: Data, currentItems: [BackupItem], replacingExistingItems: Bool, preview: BackupPreview) {
        self.data = data
        self.currentItems = currentItems
        self.replacingExistingItems = replacingExistingItems
        self.preview = preview
    }
}
