/// Current and cumulative results are independent; missing history is not zero.
public struct PeriodReadings: Equatable, Sendable {
    public let current: PeriodReading?
    public let cumulative: PeriodReading?
}
