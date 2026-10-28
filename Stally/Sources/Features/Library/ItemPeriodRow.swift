import StallyLibrary
import SwiftUI

struct ItemPeriodRow: View {
    let period: ItemPeriod
    let canResume: Bool
    let edit: (RecordEditor.Selection) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LibraryLayout.sectionSpacing) {
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
        .padding(.vertical, LibraryLayout.rowSpacing)
    }
    private var periodLabel: some View {
        HStack(alignment: .top) {
            Image(systemName: period.isOngoing ? "calendar.badge.clock" : "calendar")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: LibraryLayout.compactSpacing) {
                Text(period.isOngoing ? "Ongoing" : "Ended").font(.headline)
                Text(RecordDateDraft.display(period.startLocalDate))
                if !period.isOngoing {
                    Text("Until \(RecordDateDraft.display(period.endLocalDate))")
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .foregroundStyle(.primary)
    }
}
