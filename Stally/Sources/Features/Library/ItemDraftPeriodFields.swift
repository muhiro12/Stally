import MHUI
import StallyLibrary
import SwiftUI

struct ItemDraftPeriodFields: View {
    @Binding var input: PeriodInput
    @State private var start: RecordDateDraft
    @State private var end: RecordDateDraft

    var body: some View {
        Text("Start").mhRowTitle()
        RecordDateFields(draft: Binding(
            get: { start },
            set: { value in
                start = value
                input = .init(start: value.value, end: input.end, isOngoing: input.isOngoing)
            }
        ))
        Toggle("Ongoing", isOn: Binding(
            get: { input.isOngoing },
            set: { ongoing in
                input = .init(start: input.start, end: ongoing ? nil : end.value, isOngoing: ongoing)
            }
        ))
        if !input.isOngoing {
            Text("End").mhRowTitle()
            RecordDateFields(draft: Binding(
                get: { end },
                set: { value in
                    end = value
                    input = .init(start: input.start, end: value.value, isOngoing: false)
                }
            ))
        }
    }

    init(input: Binding<PeriodInput>) {
        _input = input
        _start = State(initialValue: .init(input.wrappedValue.start))
        _end = State(initialValue: .init(input.wrappedValue.end))
    }
}
