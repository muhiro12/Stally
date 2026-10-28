import MHUI
import StallyLibrary
import SwiftUI

struct ItemPeriodsSection: View {
    @Environment(\.mhTheme)
    private var theme
    let item: Item
    let edit: (RecordEditor.Selection) -> Void

    private var periods: [ItemPeriod] {
        (item.periods ?? []).sorted { first, second in
            first.createdAt > second.createdAt
        }
    }

    private var hasOngoingPeriod: Bool {
        periods.contains(where: \.isOngoing)
    }

    var body: some View {
        Section {
            if periods.isEmpty {
                Label {
                    VStack(alignment: .leading, spacing: theme.spacing.inline) {
                        Text("No Periods Yet").mhRowTitle()
                        Text("Keep the beginning and ending, even when dates are uncertain.")
                            .mhRowSupporting()
                    }
                } icon: {
                    Image(systemName: "calendar").mhForegroundStyle(.secondaryText)
                }
            }
            ForEach(periods) { period in
                ItemPeriodRow(period: period, canResume: !hasOngoingPeriod, edit: edit)
            }
            Button("Add Period", systemImage: "plus") {
                edit(.newPeriod)
            }
        } header: {
            MHSectionHeader("Periods")
        }
    }
}
