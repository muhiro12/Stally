import MHUI
import StallyLibrary
import SwiftUI

struct ItemDraftPeriodSections: View {
    @Binding var draft: ItemDraft
    @State private var expanded: UUID?

    var body: some View {
        Group {
            if hasAmbiguousHistory {
                Section {
                    Text(RecordError.ambiguousIdentity.localizedDescription)
                        .mhTextStyle(.supporting, colorRole: .warning)
                } header: {
                    MHSectionHeader("Periods")
                }
                ForEach(draft.newPeriods) { period in
                    Section {
                        ItemPeriodRow(input: period.input)
                        removeButton(for: period.id)
                    }
                }
            } else {
                ForEach($draft.periods) { $period in
                    Section {
                        DisclosureGroup(isExpanded: expansion(for: period.id)) {
                            ItemDraftPeriodFields(input: $period.input)
                            removeButton(for: period.id)
                        } label: {
                            ItemPeriodRow(input: period.input)
                        }
                    } header: {
                        if period.id == draft.periods.first?.id {
                            MHSectionHeader("Periods")
                        }
                    }
                }
                addSection
            }
        }
        .environment(\.calendar, RecordDateDraft.calendar)
        .environment(\.timeZone, RecordDateDraft.calendar.timeZone)
    }

    private var hasAmbiguousHistory: Bool {
        Set(draft.periods.map(\.id)).count != draft.periods.count
    }

    private var addSection: some View {
        Section {
            StallyActionButton(.addPeriod) {
                let hasOngoing = draft.periods.contains(where: \.input.isOngoing)
                let period = ItemDraft.Period(input: .init(isOngoing: !hasOngoing))
                draft.periods.append(period)
                expanded = period.id
            }
        } header: {
            if draft.periods.isEmpty {
                MHSectionHeader("Periods")
            }
        } footer: {
            if draft.periods.contains(where: { !$0.input.isOngoing }) {
                MHSectionFooter("To record a resumption, add a new period.")
            }
        }
    }

    private func removeButton(for id: UUID) -> some View {
        StallyActionButton(.removePeriod, role: .destructive) {
            draft.periods.removeAll { $0.id == id }
        }
        .buttonStyle(.borderless)
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
