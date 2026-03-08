import Foundation

/// Derived mark distribution for one category within an insight range.
public struct CollectionCategorySummary: Identifiable, Equatable, Sendable {
    public let category: ItemCategory
    public let totalMarks: Int
    public let uniqueItems: Int
    public let shareOfMarks: Double
    public let lastMarkedAt: Date?

    public var id: ItemCategory {
        category
    }

    /// Creates a category summary.
    public init(
        category: ItemCategory,
        totalMarks: Int,
        uniqueItems: Int,
        shareOfMarks: Double,
        lastMarkedAt: Date?
    ) {
        self.category = category
        self.totalMarks = totalMarks
        self.uniqueItems = uniqueItems
        self.shareOfMarks = shareOfMarks
        self.lastMarkedAt = lastMarkedAt
    }
}
