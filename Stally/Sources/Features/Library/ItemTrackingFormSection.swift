import SwiftUI

struct ItemTrackingFormSection: View {
    private static let months = 1...12

    @Binding var state: ItemTrackingFormState
    let allowsDisablingMarks: Bool

    var body: some View {
        Section {
            Toggle("Record Marks", isOn: $state.recordsMarks)
                .disabled(!allowsDisablingMarks && state.recordsMarks)
        } footer: {
            if !allowsDisablingMarks {
                Text("Keep Marks enabled to preserve this item's existing history.")
            } else {
                Text("Items without Marks stay in your collection and are excluded from Review and choice counts.")
            }
        }

        Section {
            Picker("Precision", selection: $state.precision) {
                ForEach(ItemTrackingFormState.Precision.allCases) { precision in
                    Text(precision.title).tag(precision)
                }
            }
            .labeledContentStyle(.automatic)
            if state.requiresStartRepair {
                startRepairControls
            }
            if state.precision != .unknown {
                yearInput
            }
            if state.precision == .month || state.precision == .day {
                Picker("Month", selection: $state.month) {
                    Text("Not Set").tag(Int?.none)
                    ForEach(Self.months, id: \.self) { month in
                        Text(month, format: .number).tag(Optional(month))
                    }
                }
                .labeledContentStyle(.automatic)
            }
            if state.precision == .day {
                Picker("Day", selection: $state.day) {
                    Text("Not Set").tag(Int?.none)
                    ForEach(1...state.maximumDay, id: \.self) { day in
                        Text(day, format: .number).tag(Optional(day))
                    }
                }
                .labeledContentStyle(.automatic)
            }
        } header: {
            Text("Start")
        } footer: {
            Text("Enter only what you know. Time keeps passing while an item is archived.")
        }
        .onChange(of: state.precision) {
            state.changePrecision()
        }
        .onChange(of: state.year) {
            state.validateSelectedDay()
        }
        .onChange(of: state.month) {
            state.validateSelectedDay()
        }
    }

    @ViewBuilder private var startRepairControls: some View {
        Text("The stored start is invalid. Edit or clear it before saving.")
            .foregroundStyle(.secondary)
        Button("Clear Invalid Start") {
            state.clearInvalidStart()
        }
    }

    private var yearInput: some View {
        LabeledContent("Year") {
            TextField("Year", text: $state.year)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
        }
    }
}
