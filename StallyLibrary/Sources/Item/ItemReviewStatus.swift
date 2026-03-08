/// Review status derived from an item's recent mark history.
public enum ItemReviewStatus: String, CaseIterable, Equatable, Sendable {
    /// Item has existed long enough without a first mark.
    case untouched

    /// Item was marked before but now looks inactive.
    case dormant

    /// Item does not currently need review.
    case healthy

    /// Archived item with history that might deserve another turn.
    case recoveryCandidate

    /// Archived item with no history.
    case coldArchive

    /// Indicates whether this status should appear in review lanes.
    public var needsReview: Bool {
        switch self {
        case .untouched, .dormant, .recoveryCandidate:
            true
        case .healthy, .coldArchive:
            false
        }
    }
}
