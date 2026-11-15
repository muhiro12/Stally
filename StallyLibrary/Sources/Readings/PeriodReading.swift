import Foundation

/// A derived reading, never a replacement for the recorded boundary knowledge.
public struct PeriodReading: Equatable, Sendable {
    /// The exact day subtotal from periods whose two endpoints are known by day.
    public let exactDays: Int
    /// Calendar month differences from periods whose least precise endpoint is a month.
    public let approximateMonths: Int
    /// Calendar year differences from periods whose least precise endpoint is a year.
    public let approximateYears: Int
    public let includedCount: Int
    public let excludedCount: Int
    public let hasApproximation: Bool
    /// Partial dates permit a possible overlap; this sum assumes the periods do not overlap.
    public let mayOverlap: Bool

    /// Display conversion only; original year/month differences remain available to explain it.
    public var estimatedDays: Double {
        let daysPerYear = 365.2425
        let monthsPerYear = 12.0
        return Double(exactDays) + Double(approximateMonths) * daysPerYear / monthsPerYear
            + Double(approximateYears) * daysPerYear
    }
}
