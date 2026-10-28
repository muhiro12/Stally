import StallyLibrary
import SwiftUI

struct ItemPeriodsSection: View {
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
                    VStack(alignment: .leading, spacing: LibraryLayout.compactSpacing) {
                        Text("No Periods Yet")
                        Text("Keep the beginning and ending, even when dates are uncertain.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "calendar").foregroundStyle(.secondary)
                }
                .padding(.vertical, LibraryLayout.rowSpacing)
            }
            ForEach(periods) { period in
                ItemPeriodRow(period: period, canResume: !hasOngoingPeriod, edit: edit)
            }
            Button("Add Period", systemImage: "plus") {
                edit(.newPeriod)
            }
        } header: {
            Text("Periods")
        }
    }
}
