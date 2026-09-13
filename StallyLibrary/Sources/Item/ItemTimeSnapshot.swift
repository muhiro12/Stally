/// A reading of elapsed calendar time, independent of archive state and persistence.
public enum ItemTimeSnapshot: Equatable, Sendable {
    case unknown
    case invalidStart
    case notStarted(ItemStart)
    /// Units are days, completed months, or completed years according to start precision.
    case elapsed(start: ItemStart, days: ClosedRange<Int>, units: ClosedRange<Int>)
}
