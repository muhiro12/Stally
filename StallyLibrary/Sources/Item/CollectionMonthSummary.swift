import Foundation

/// Derived monthly activity metrics for a collection inside an insight range.
public struct CollectionMonthSummary: Equatable, Sendable {
    public let monthStart: Date
    public let monthTitle: String
    public let markCount: Int
    public let activeDays: Int
    public let uniqueItems: Int
    public let uniqueCategories: Int
    public let averageMarksPerActiveDay: Double

    public init(
        monthStart: Date,
        monthTitle: String,
        markCount: Int,
        activeDays: Int,
        uniqueItems: Int,
        uniqueCategories: Int,
        averageMarksPerActiveDay: Double
    ) {
        self.monthStart = monthStart
        self.monthTitle = monthTitle
        self.markCount = markCount
        self.activeDays = activeDays
        self.uniqueItems = uniqueItems
        self.uniqueCategories = uniqueCategories
        self.averageMarksPerActiveDay = averageMarksPerActiveDay
    }
}
