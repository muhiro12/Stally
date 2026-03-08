import Foundation

/// One derived collection activity bucket for a calendar day.
public struct CollectionActivityDay: Identifiable, Equatable, Sendable {
    public let date: Date
    public let markCount: Int
    public let uniqueItemCount: Int
    public let uniqueCategoryCount: Int

    public var id: Date {
        date
    }

    public var isActive: Bool {
        markCount > .zero
    }

    /// Creates a derived activity day.
    public init(
        date: Date,
        markCount: Int,
        uniqueItemCount: Int,
        uniqueCategoryCount: Int
    ) {
        self.date = date
        self.markCount = markCount
        self.uniqueItemCount = uniqueItemCount
        self.uniqueCategoryCount = uniqueCategoryCount
    }
}
