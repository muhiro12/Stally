import MHUI
import SwiftUI

struct RecordDateFields: View {
    @Binding var draft: RecordDateDraft
    var allowsPartialDate = true

    var body: some View {
        if draft.unsupportedValue != nil {
            Text("This saved date needs review. It will be preserved until you replace it.")
                .mhTextStyle(.supporting, colorRole: .warning)
            TextField(
                "Saved Date",
                text: Binding(
                    get: {
                        draft.unsupportedValue ?? ""
                    },
                    set: { value in
                        draft.unsupportedValue = value
                    }
                ))
        } else {
            if allowsPartialDate {
                Picker(
                    "Date Precision",
                    selection: Binding(
                        get: {
                            draft.precision
                        },
                        set: { value in
                            draft.selectPrecision(value)
                        }
                    )
                ) {
                    ForEach(RecordDateDraft.Precision.allCases) { precision in
                        Text(precision.title).tag(precision)
                    }
                }
            }
            switch draft.precision {
            case .unknown:
                Text("Only record the date parts you know.").mhRowSupporting()
            case .year, .month:
                TextField("Year", text: $draft.year)
                    .autocorrectionDisabled()
                if draft.precision == .month {
                    Picker("Month", selection: $draft.month) {
                        ForEach(1...RecordDateDraft.calendar.monthSymbols.count, id: \.self) { month in
                            Text(RecordDateDraft.calendar.monthSymbols[month - 1]).tag(month)
                        }
                    }
                }
            case .day:
                DatePicker("Date", selection: $draft.date, displayedComponents: .date)
                if !allowsPartialDate {
                    Toggle("Include Time", isOn: $draft.includesTime)
                    if draft.includesTime {
                        DatePicker("Time", selection: $draft.date, displayedComponents: .hourAndMinute)
                    }
                }
            }
        }
    }
}
