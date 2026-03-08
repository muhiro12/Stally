/// Thresholds used to derive review status from item history.
public struct ItemReviewPolicy: Codable, Equatable, Sendable {
    /// Days an unmarked item can stay healthy before becoming untouched.
    public let untouchedGraceDays: Int

    /// Days since last mark before an active item becomes dormant.
    public let dormantAfterDays: Int

    /// Creates a review policy.
    public init(
        untouchedGraceDays: Int = 14,
        dormantAfterDays: Int = 30
    ) {
        self.untouchedGraceDays = max(1, untouchedGraceDays)
        self.dormantAfterDays = max(1, dormantAfterDays)
    }
}
