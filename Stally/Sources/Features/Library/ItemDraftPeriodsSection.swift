import MHUI
import StallyLibrary
import SwiftUI

struct ItemDraftPeriodsSection: View {
    @Binding var draft: ItemDraft
    @State private var expanded: UUID?

    var body: some View {
        Section {
            if hasAmbiguousHistory {
                Text(RecordError.ambiguousIdentity.localizedDescription)
                    .mhTextStyle(.supporting, colorRole: .warning)
                ForEach(draft.newPeriods) { period in
                    ItemPeriodRow(input: period.input)
                    StallyActionButton(.removePeriod, role: .destructive) {
                        draft.periods.removeAll { $0.id == period.id }
                    }
                }
            } else {
                periodRows
            }
        } header: {
            MHSectionHeader("Periods")
        } footer: {
            if !hasAmbiguousHistory, draft.periods.contains(where: { !$0.input.isOngoing }) {
                MHSectionFooter("To record a resumption, add a new period.")
            }
        }
        .environment(\.calendar, RecordDateDraft.calendar)
        .environment(\.timeZone, RecordDateDraft.calendar.timeZone)
    }

    private var hasAmbiguousHistory: Bool {
        Set(draft.periods.map(\.id)).count != draft.periods.count
    }

    @ViewBuilder private var periodRows: some View {
        ForEach($draft.periods) { $period in
            DisclosureGroup(isExpanded: expansion(for: period.id)) {
                ItemDraftPeriodFields(input: $period.input)
                StallyActionButton(.removePeriod, role: .destructive) { [id = period.id] in
                    draft.periods.removeAll { $0.id == id }
                }
                .buttonStyle(.borderless)
            } label: {
                ItemPeriodRow(input: period.input)
            }
        }
        StallyActionButton(.addPeriod) {
            let hasOngoing = draft.periods.contains(where: \.input.isOngoing)
            let period = ItemDraft.Period(input: .init(isOngoing: !hasOngoing))
            draft.periods.append(period)
            expanded = period.id
        }
    }

    private func expansion(for id: UUID) -> Binding<Bool> {
        .init(
            get: { expanded == id },
            set: { open in
                expanded = open ? id : nil
            }
        )
    }
}
