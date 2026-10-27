/// The user's boundary knowledge, separate from registration metadata and identity.
public struct PeriodInput: Sendable {
    /// Unknown or canonical year, month, or day knowledge.
    public let start: String?
    /// Unknown or canonical boundary; nil for ongoing periods.
    public let end: String?
    /// Whether this relationship period is continuing.
    public let isOngoing: Bool

    /// Missing boundaries stay unknown; an ongoing period must not have an end.
    public init(start: String? = nil, end: String? = nil, isOngoing: Bool = true) {
        self.start = start
        self.end = end
        self.isOngoing = isOngoing
    }
}
