import MHUI
import StallyLibrary
import SwiftUI

struct ItemPeriodRow: View {
    @Environment(\.mhTheme)
    private var theme
    let period: ItemPeriod
    let canResume: Bool
    let edit: (RecordEditor.Selection) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            Button {
                edit(.period(period))
            } label: {
                periodLabel
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if period.isOngoing {
                Button("End Period") {
                    edit(.end(period))
                }.buttonStyle(.borderless)
            } else if canResume {
                Button("Resume with a new period") {
                    edit(.resume(period))
                }.buttonStyle(.borderless)
            }
        }
    }
    private var periodLabel: some View {
        HStack(alignment: .top) {
            Image(systemName: period.isOngoing ? "calendar.badge.clock" : "calendar")
                .mhForegroundStyle(.secondaryText)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: theme.spacing.inline) {
                Text(period.isOngoing ? "Ongoing" : "Ended").mhRowTitle()
                Text(RecordDateDraft.display(period.startLocalDate)).mhTextStyle(.body)
                if !period.isOngoing {
                    Text("Until \(RecordDateDraft.display(period.endLocalDate))")
                        .mhForegroundStyle(.secondaryText)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .mhForegroundStyle(.tertiaryText)
                .accessibilityHidden(true)
        }
        .mhForegroundStyle(.primaryText)
    }
}
