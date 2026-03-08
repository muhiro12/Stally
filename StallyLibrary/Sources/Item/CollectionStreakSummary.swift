import Foundation

/// Aggregate streak values derived from a collection activity range.
public struct CollectionStreakSummary: Equatable, Sendable {
    public let range: ItemInsightsRange
    public let currentStreakDays: Int
    public let bestStreakDays: Int
    public let longestIdleGapDays: Int
    public let daysSinceLastActive: Int?
    public let lastActiveDate: Date?

    /// Creates a streak summary.
    public init(
        range: ItemInsightsRange,
        currentStreakDays: Int,
        bestStreakDays: Int,
        longestIdleGapDays: Int,
        daysSinceLastActive: Int?,
        lastActiveDate: Date?
    ) {
        self.range = range
        self.currentStreakDays = currentStreakDays
        self.bestStreakDays = bestStreakDays
        self.longestIdleGapDays = longestIdleGapDays
        self.daysSinceLastActive = daysSinceLastActive
        self.lastActiveDate = lastActiveDate
    }
}
