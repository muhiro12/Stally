import Foundation

/// Derived ranking metrics for one item inside an insight range.
public struct CollectionItemRanking: Identifiable, Equatable, Sendable {
    public let itemID: UUID
    public let totalMarksInRange: Int
    public let activeDaysInRange: Int
    public let totalLifetimeMarks: Int
    public let lastMarkedAt: Date?
    public let isArchived: Bool

    public var id: UUID {
        itemID
    }

    /// Creates an item ranking record.
    public init(
        itemID: UUID,
        totalMarksInRange: Int,
        activeDaysInRange: Int,
        totalLifetimeMarks: Int,
        lastMarkedAt: Date?,
        isArchived: Bool
    ) {
        self.itemID = itemID
        self.totalMarksInRange = totalMarksInRange
        self.activeDaysInRange = activeDaysInRange
        self.totalLifetimeMarks = totalLifetimeMarks
        self.lastMarkedAt = lastMarkedAt
        self.isArchived = isArchived
    }
}
