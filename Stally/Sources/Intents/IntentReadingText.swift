import Foundation
import StallyLibrary

enum IntentReadingText {
    static func describe(_ readings: PeriodReadings) -> String {
        String(
            localized:
                "Current: \(describe(readings.current))\nCumulative: \(describe(readings.cumulative))"
        )
    }

    private static func describe(_ reading: PeriodReading?) -> String {
        guard let reading, reading.includedCount > 0 else {
            return String(localized: "Not enough recorded dates")
        }
        var text = String(localized: "\(reading.exactDays) exact days")
        if reading.hasApproximation {
            text += String(
                localized:
                    "; about \(reading.approximateYears) years + \(reading.approximateMonths) months (partial dates)"
            )
        }
        if reading.excludedCount > 0 {
            text += String(localized: "; calculable subtotal, excluding \(reading.excludedCount) periods")
        }
        if reading.mayOverlap { text += String(localized: "; assumes partial-date periods do not overlap") }
        return text
    }
}
