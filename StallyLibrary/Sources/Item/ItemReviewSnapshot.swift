import Foundation

/// Derived review-facing snapshot for one item.
public struct ItemReviewSnapshot: Equatable, Identifiable, Sendable {
    /// Related item identifier.
    public let itemID: UUID

    /// Current derived review status.
    public let status: ItemReviewStatus

    /// Total recorded marks for the item.
    public let totalMarks: Int

    /// Item creation timestamp.
    public let createdAt: Date

    /// Archive timestamp when archived.
    public let archivedAt: Date?

    /// Most recent local mark date.
    public let lastMarkedAt: Date?

    /// Number of elapsed days since creation.
    public let daysSinceCreated: Int

    /// Number of elapsed days since the most recent mark.
    public let daysSinceLastMark: Int?

    /// Stable identifier for list rendering.
    public var id: UUID {
        itemID
    }

    /// Indicates whether the snapshot should appear in review lanes.
    public var needsReview: Bool {
        status.needsReview
    }
}
