import MHUI
import StallyLibrary
import SwiftUI

struct PeriodReadingsSection: View {
    let item: Item

    private let refreshInterval = 60.0

    var body: some View {
        Section {
            TimelineView(.periodic(from: .now, by: refreshInterval)) { timeline in
                if let readings = try? PeriodReadingOperations.readings(
                    for: item,
                    today: MarkOperations.localDateTime(at: timeline.date, includesTime: false)
                ) {
                    VStack(alignment: .leading) {
                        readingRow("Current Period", reading: readings.current)
                        Divider()
                        readingRow("Recorded Time Together", reading: readings.cumulative)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("Review conflicting periods before calculating time together.")
                }
            }
        } header: {
            MHSectionHeader("Time Together")
        } footer: {
            MHSectionFooter("Only recorded periods are added. Gaps are excluded.")
        }
    }

    private func readingRow(_ title: LocalizedStringKey, reading: PeriodReading?) -> some View {
        VStack(alignment: .leading) {
            Text(title).mhRowTitle()
            if let reading, reading.includedCount > 0 {
                if reading.hasApproximation {
                    let daysPerYear = 365.2425
                    let estimate = reading.estimatedDays / daysPerYear
                    let years = estimate.formatted(.number.precision(.fractionLength(0...1)))
                    Text("About \(years) years")
                    Text("Calculated from differences in recorded years or months, plus exact days.")
                        .mhRowSupporting()
                    Text(basis(reading)).mhRowSupporting()
                } else {
                    Text("\(reading.exactDays) days")
                }
                if reading.excludedCount > 0 {
                    Text("Calculable subtotal. \(reading.excludedCount) periods have unknown or future boundaries.")
                        .mhRowSupporting()
                }
                if reading.mayOverlap {
                    Text("Partial dates may overlap. This estimate assumes separate periods.")
                        .mhRowSupporting()
                }
            } else {
                Text("Not enough recorded dates").mhRowSupporting()
            }
        }
    }
    private func basis(_ reading: PeriodReading) -> LocalizedStringResource {
        let years = reading.approximateYears
        let months = reading.approximateMonths
        let days = reading.exactDays
        return "Years: \(years), months: \(months), days: \(days)"
    }
}
