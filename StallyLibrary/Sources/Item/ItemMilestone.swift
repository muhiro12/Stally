/// A yearly milestone whose period retains the original date knowledge.
public struct ItemMilestone: Equatable, Sendable {
    /// Number of years since the recorded start, beginning with the first year.
    public let years: Int
    /// Exact day, month, or year in which this milestone occurs.
    public let period: ItemStart
}
