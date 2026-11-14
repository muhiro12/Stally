import Foundation

/// Readable period results retain missing-history and partial-date qualifications.
public enum PeriodReadingText {
    /// Uses the same qualified wording for the app's report and Get Time Together.
    public static func describe(_ readings: PeriodReadings) -> String {
        let current = describe(readings.current)
        let cumulative = describe(readings.cumulative)
        return String(
            localized:
                "Current: \(current)\nCumulative: \(cumulative)",
            bundle: .module
        )
    }

    private static func describe(_ reading: PeriodReading?) -> String {
        guard let reading, reading.includedCount > 0 else {
            return String(localized: "Not enough recorded dates", bundle: .module)
        }
        var text = String(localized: "\(reading.exactDays) exact days", bundle: .module)
        if reading.hasApproximation {
            text += String(
                localized:
                    "; about \(reading.approximateYears) years + \(reading.approximateMonths) months (partial dates)",
                bundle: .module
            )
        }
        if reading.excludedCount > 0 {
            text += String(
                localized: "; calculable subtotal, excluding \(reading.excludedCount) periods",
                bundle: .module
            )
        }
        if reading.mayOverlap {
            text += String(localized: "; assumes partial-date periods do not overlap", bundle: .module)
        }
        return text
    }
}
