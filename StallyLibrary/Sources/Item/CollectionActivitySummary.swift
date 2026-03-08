import Foundation

/// Aggregate insight values derived from a collection activity range.
public struct CollectionActivitySummary: Equatable, Sendable {
    public let range: ItemInsightsRange
    public let totalMarks: Int
    public let activeDays: Int
    public let uniqueMarkedItems: Int
    public let uniqueMarkedCategories: Int
    public let averageMarksPerActiveDay: Double
    public let busiestDay: CollectionActivityDay?

    /// Creates an aggregate activity summary.
    public init(
        range: ItemInsightsRange,
        totalMarks: Int,
        activeDays: Int,
        uniqueMarkedItems: Int,
        uniqueMarkedCategories: Int,
        averageMarksPerActiveDay: Double,
        busiestDay: CollectionActivityDay?
    ) {
        self.range = range
        self.totalMarks = totalMarks
        self.activeDays = activeDays
        self.uniqueMarkedItems = uniqueMarkedItems
        self.uniqueMarkedCategories = uniqueMarkedCategories
        self.averageMarksPerActiveDay = averageMarksPerActiveDay
        self.busiestDay = busiestDay
    }
}
