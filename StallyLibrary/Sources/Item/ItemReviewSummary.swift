/// Aggregated counts for all review statuses.
public struct ItemReviewSummary: Equatable, Sendable {
    /// Total item count represented by the summary.
    public let totalItems: Int

    /// Count of untouched items.
    public let untouchedCount: Int

    /// Count of dormant items.
    public let dormantCount: Int

    /// Count of healthy items.
    public let healthyCount: Int

    /// Count of recovery candidate items.
    public let recoveryCandidateCount: Int

    /// Count of cold archived items.
    public let coldArchiveCount: Int

    /// Total items that currently need review.
    public var totalReviewCount: Int {
        untouchedCount + dormantCount + recoveryCandidateCount
    }

    /// Total active items that currently need review.
    public var activeReviewCount: Int {
        untouchedCount + dormantCount
    }
}
