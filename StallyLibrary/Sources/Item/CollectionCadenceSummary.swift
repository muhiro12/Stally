import Foundation

/// Derived weekly cadence metrics for a collection inside an insight range.
public struct CollectionCadenceSummary: Equatable, Sendable {
    public let range: ItemInsightsRange
    public let totalWeeks: Int
    public let activeWeeks: Int
    public let averageMarksPerWeek: Double
    public let averageActiveDaysPerWeek: Double
    public let weekdayMarks: Int
    public let weekendMarks: Int
    public let weekendShareOfMarks: Double
    public let consistencyScore: Double
    public let busiestWeekStart: Date?

    public init(
        range: ItemInsightsRange,
        totalWeeks: Int,
        activeWeeks: Int,
        averageMarksPerWeek: Double,
        averageActiveDaysPerWeek: Double,
        weekdayMarks: Int,
        weekendMarks: Int,
        weekendShareOfMarks: Double,
        consistencyScore: Double,
        busiestWeekStart: Date?
    ) {
        self.range = range
        self.totalWeeks = totalWeeks
        self.activeWeeks = activeWeeks
        self.averageMarksPerWeek = averageMarksPerWeek
        self.averageActiveDaysPerWeek = averageActiveDaysPerWeek
        self.weekdayMarks = weekdayMarks
        self.weekendMarks = weekendMarks
        self.weekendShareOfMarks = weekendShareOfMarks
        self.consistencyScore = consistencyScore
        self.busiestWeekStart = busiestWeekStart
    }
}
