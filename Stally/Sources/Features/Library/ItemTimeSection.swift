import SwiftUI

struct ItemTimeSection: View {
    let snapshot: ItemTimeSnapshot

    var body: some View {
        Section {
            switch snapshot {
            case .unknown:
                LabeledContent("Start") {
                    Text("Not Set")
                }
            case .invalidStart:
                Text("The stored start is invalid. Edit or clear it before saving.")
            case .notStarted(let start):
                startRow(start)
                LabeledContent("Elapsed Time") {
                    Text("Not Started")
                }
            case let .elapsed(start, _, units):
                startRow(start)
                LabeledContent("Elapsed Time") {
                    elapsedText(units, precision: start.precision)
                }
            }
        }
    }

    private func startRow(_ start: ItemStart) -> some View {
        LabeledContent("Start") {
            ItemStartDateText(start: start)
        }
    }

    private func elapsedText(_ units: ClosedRange<Int>, precision: ItemStart.Precision) -> Text {
        switch precision {
        case .day:
            if units.lowerBound == 0 {
                Text("Starts Today")
            } else if units.lowerBound == 1 {
                Text("1 day")
            } else {
                Text("\(units.lowerBound) days")
            }
        case .month:
            approximateMonths(units)
        case .year:
            approximateYears(units)
        }
    }

    private func approximateMonths(_ units: ClosedRange<Int>) -> Text {
        if units.upperBound == 0 {
            Text("Less than a month")
        } else if units.lowerBound == units.upperBound {
            if units.lowerBound == 1 {
                Text("About a month")
            } else {
                Text("About \(units.lowerBound) months")
            }
        } else {
            Text("About \(units.lowerBound)–\(units.upperBound) months")
        }
    }

    private func approximateYears(_ units: ClosedRange<Int>) -> Text {
        if units.upperBound == 0 {
            Text("Less than a year")
        } else if units.lowerBound == units.upperBound {
            if units.lowerBound == 1 {
                Text("About a year")
            } else {
                Text("About \(units.lowerBound) years")
            }
        } else {
            Text("About \(units.lowerBound)–\(units.upperBound) years")
        }
    }
}
