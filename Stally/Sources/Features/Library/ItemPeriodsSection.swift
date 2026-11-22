import MHUI
import StallyLibrary
import SwiftUI

struct ItemPeriodsSection: View {
    @Environment(\.mhTheme)
    private var theme
    @Environment(Item.self)
    private var item

    private var periods: [ItemPeriod] {
        PeriodOperations.orderedPeriods(for: item)
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
                ItemPeriodRow(input: .init(
                    start: period.startLocalDate, end: period.endLocalDate, isOngoing: period.isOngoing
                ))
            }
        } header: {
            MHSectionHeader("Periods")
        }
    }
}
