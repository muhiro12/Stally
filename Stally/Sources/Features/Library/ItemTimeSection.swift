import SwiftUI

struct ItemTimeSection: View {
    @Environment(\.locale)
    private var locale

    let snapshot: ItemTimeSnapshot
    let milestone: ItemMilestone?
    let report: String

    var body: some View {
        Section {
            reading

            if let milestone {
                LabeledContent("Yearly Milestone") {
                    VStack(alignment: .trailing) {
                        if milestone.years == 1 {
                            Text("1 year together")
                        } else {
                            Text("\(milestone.years) years together")
                        }
                        ItemStartDateText(start: milestone.period)
                    }
                }
            }

            ShareLink(item: report) {
                Label("Share Time Together", systemImage: "square.and.arrow.up")
            }
        } footer: {
            if let milestone, milestone.period.precision != .day {
                Text("The milestone falls within the known month or year; its exact day is unknown.")
            }
        }
    }

    @ViewBuilder private var reading: some View {
        switch snapshot {
        case .unknown:
            LabeledContent("Start") {
                Text("Not Set")
            }
        case .invalidStart:
            Text("The stored start is invalid. Edit or clear it before saving.")
        case .notStarted(let start), .elapsed(let start, _, _):
            LabeledContent("Start") {
                ItemStartDateText(start: start)
            }
            LabeledContent("Elapsed Time") {
                Text(ItemTimeOperations.elapsedText(for: snapshot, locale: locale))
            }
        }
    }
}
