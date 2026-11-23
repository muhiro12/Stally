import MHUI
import StallyLibrary
import SwiftUI

struct ItemPeriodRow: View {
    @Environment(\.mhTheme)
    private var theme
    let input: PeriodInput

    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: input.isOngoing ? "calendar.badge.clock" : "calendar")
                .mhForegroundStyle(.secondaryText)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: theme.spacing.inline) {
                Text(input.isOngoing ? "Ongoing" : "Ended").mhRowTitle()
                Text(RecordDateDraft.display(input.start)).mhTextStyle(.body)
                if !input.isOngoing {
                    Text("Until \(RecordDateDraft.display(input.end))")
                        .mhForegroundStyle(.secondaryText)
                }
            }
        }
        .mhForegroundStyle(.primaryText)
    }
}
