import MHUI
import StallyLibrary
import SwiftUI

struct ItemDraftPeriodsSection: View {
    @Binding var draft: ItemDraft
    @State private var editing: ItemDraft.Period?

    var body: some View {
        if !draft.newPeriods.isEmpty {
            Section {
                ForEach(draft.newPeriods) { period in
                    Button {
                        editing = period
                    } label: {
                        VStack(alignment: .leading) {
                            Text(RecordDateDraft.display(period.input.start))
                            if period.input.isOngoing {
                                Text("Ongoing").mhRowSupporting()
                            } else {
                                Text(RecordDateDraft.display(period.input.end)).mhRowSupporting()
                            }
                        }
                    }
                }
                .onDelete { offsets in
                    draft.newPeriods.remove(atOffsets: offsets)
                }
            } header: {
                MHSectionHeader("Periods to Add")
            } footer: {
                Text("These periods will be added when you save the Item. Existing periods stay unchanged.")
            }
            .sheet(item: $editing) { period in
                ItemPeriodReview(candidate: .init(
                    start: period.input.start,
                    end: period.input.end,
                    continuation: period.input.isOngoing ? .ongoing : .ended,
                    basis: .relationship,
                    evidence: ""
                ),
                reviewed: nil
                ) { input in
                    if let index = draft.newPeriods.firstIndex(where: { $0.id == period.id }) {
                        draft.newPeriods[index].input = input
                    }
                }
            }
        }
    }
}
