import Foundation

/// Derived mark distribution for one weekday inside an insight range.
public struct CollectionWeekdaySummary: Equatable, Sendable {
    public let weekday: Int
    public let title: String
    public let shortTitle: String
    public let markCount: Int
    public let activeDays: Int
    public let shareOfMarks: Double

    public init(
        weekday: Int,
        title: String,
        shortTitle: String,
        markCount: Int,
        activeDays: Int,
        shareOfMarks: Double
    ) {
        self.weekday = weekday
        self.title = title
        self.shortTitle = shortTitle
        self.markCount = markCount
        self.activeDays = activeDays
        self.shareOfMarks = shareOfMarks
    }
}
