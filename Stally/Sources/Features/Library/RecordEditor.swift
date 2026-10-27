import StallyLibrary
import SwiftData
import SwiftUI

struct RecordEditor: View {
    enum Selection: Identifiable {
        case newMark
        case mark(ItemMark)
        case newPeriod
        case period(ItemPeriod)

        var id: String {
            switch self {
            case .newMark:
                "newMark"
            case .mark(let mark):
                mark.uuid.uuidString
            case .newPeriod:
                "newPeriod"
            case .period(let period):
                period.uuid.uuidString
            }
        }
    }

    private static var today: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = .init(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: .now)
    }

    @Environment(\.modelContext)
    private var context
    @Environment(\.dismiss)
    private var dismiss
    @Environment(RemoteUpdateOperations.self)
    private var updates
    let item: Item
    let selection: Selection
    @State private var start = ""
    @State private var end = ""
    @State private var ongoing = true
    @State private var errorMessage: String?
    @State private var saving = false
    @State private var confirmingDelete = false

    private var isMark: Bool {
        switch selection {
        case .newMark, .mark:
            true
        case .newPeriod, .period:
            false
        }
    }

    var body: some View {
        NavigationStack {
            recordForm
                .disabled(saving)
                .navigationTitle(isMark ? String(localized: "Mark") : String(localized: "Period"))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
                }
                .confirmationDialog(
                    "Delete this record?",
                    isPresented: $confirmingDelete,
                    titleVisibility: .visible
                ) {
                    Button("Delete Record", role: .destructive) {
                        mutate {
                            switch selection {
                            case .mark(let mark):
                                try MarkOperations.delete(mark, context: context)
                            case .period(let period):
                                try PeriodOperations.delete(period, context: context)
                            case .newMark, .newPeriod:
                                break
                            }
                        }
                    }
                }
        }
    }

    private var recordForm: some View {
        Form {
            dateSection
            if case .period(let period) = selection, !period.isOngoing {
                Button("Resume with a new period") {
                    mutate {
                        try PeriodOperations.resume(period, on: nil, today: Self.today, context: context)
                    }
                }
            }
            switch selection {
            case .mark, .period:
                Button("Delete Record", role: .destructive) { confirmingDelete = true }
            case .newMark, .newPeriod:
                EmptyView()
            }
            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red)
            }
        }
    }

    private var dateSection: some View {
        Section {
            TextField(
                isMark ? String(localized: "Date and optional time") : String(localized: "Start"),
                text: $start
            )
            if !isMark {
                Toggle("Ongoing", isOn: $ongoing)
                if !ongoing {
                    TextField("End", text: $end)
                }
            }
        } footer: {
            Text(
                isMark
                    ? String(localized: "YYYY-MM-DD or YYYY-MM-DDTHH:mm")
                    : String(localized: "YYYY, YYYY-MM, or YYYY-MM-DD. Leave unknown dates empty.")
            )
        }
    }

    init(item: Item, selection: Selection) {
        self.item = item
        self.selection = selection
        switch selection {
        case .newMark:
            _start = State(initialValue: Self.today)
        case .mark(let mark):
            _start = State(initialValue: mark.localDateTime)
        case .newPeriod:
            break
        case .period(let period):
            _start = State(initialValue: period.startLocalDate ?? "")
            _end = State(initialValue: period.endLocalDate ?? "")
            _ongoing = State(initialValue: period.isOngoing)
        }
    }

    private func save() {
        mutate {
            if isMark {
                if case .mark(let mark) = selection {
                    try MarkOperations.correct(mark, localDateTime: start, context: context)
                } else {
                    try MarkOperations.add(to: item, localDateTime: start, context: context)
                }
            } else {
                let startValue = start.isEmpty ? nil : start
                let endValue = ongoing || end.isEmpty ? nil : end
                if case .period(let period) = selection {
                    try PeriodOperations.correct(
                        period,
                        input: .init(start: startValue, end: endValue, isOngoing: ongoing),
                        today: Self.today,
                        context: context
                    )
                } else {
                    try PeriodOperations.add(
                        to: item,
                        input: .init(start: startValue, end: endValue, isOngoing: ongoing),
                        today: Self.today,
                        context: context
                    )
                }
            }
        }
    }

    private func mutate(_ operation: @escaping () throws -> Void) {
        saving = true
        Task {
            defer { saving = false }
            do {
                try await updates.performMutation(operation)
                dismiss()
            } catch { errorMessage = error.localizedDescription }
        }
    }
}
