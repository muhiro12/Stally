import MHUI
import StallyLibrary
import SwiftData
import SwiftUI

struct RecordEditor: View {
    enum Selection: Identifiable {
        case newMark
        case mark(ItemMark)
        case newPeriod
        case period(ItemPeriod)
        case end(ItemPeriod)
        case resume(ItemPeriod)

        var id: String {
            switch self {
            case .newMark:
                "newMark"
            case .mark(let mark):
                "mark-\(mark.persistentModelID)"
            case .newPeriod:
                "newPeriod"
            case .period(let period):
                "period-\(period.persistentModelID)"
            case .end(let period):
                "end-\(period.persistentModelID)"
            case .resume(let period):
                "resume-\(period.persistentModelID)"
            }
        }

        var title: LocalizedStringResource {
            switch self {
            case .newMark:
                "Add Mark"
            case .mark:
                "Edit Mark"
            case .newPeriod:
                "Add Period"
            case .period:
                "Edit Period"
            case .end:
                "End Period"
            case .resume:
                "Resume Period"
            }
        }
    }

    @Environment(\.modelContext)
    private var context
    @Environment(\.dismiss)
    private var dismiss
    @Environment(RecordWriteSession.self)
    private var writeSession
    @Environment(Item.self)
    private var item
    let selection: Selection
    @State private var start: RecordDateDraft
    @State private var end: RecordDateDraft
    @State private var ongoing = true
    @State private var originalMark: String?
    @State private var originalPeriod: PeriodInput?
    @State private var errorMessage: String?
    @State private var saving = false
    @State private var confirmingDelete = false

    var body: some View {
        NavigationStack {
            recordForm
                .environment(\.calendar, RecordDateDraft.calendar)
                .environment(\.timeZone, RecordDateDraft.calendar.timeZone)
                .disabled(saving)
                .navigationTitle(Text(selection.title))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        StallyActionButton(.cancel) {
                            dismiss()
                        }.disabled(saving)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        StallyActionButton(.save, action: save).disabled(saving)
                    }
                }
                .interactiveDismissDisabled(saving)
                .confirmationDialog(
                    "Delete this record?", isPresented: $confirmingDelete, titleVisibility: .visible
                ) {
                    StallyActionButton(.deleteRecord, role: .destructive, action: deleteRecord)
                }
        }
        .modifier(StallyUpdateRequiredModifier())
    }

    @ViewBuilder private var recordFields: some View {
        switch selection {
        case .newMark, .mark:
            Section {
                RecordDateFields(draft: $start, allowsPartialDate: false)
            } footer: {
                MHSectionFooter("Each Mark is a separate occurrence, even on the same day. Time is optional.")
            }
        case .end:
            Section {
                RecordDateFields(draft: $end)
            } header: {
                MHSectionHeader("End")
            }
        case .resume:
            Section {
                RecordDateFields(draft: $start)
            } header: {
                MHSectionHeader("Start")
            } footer: {
                MHSectionFooter("Resuming adds a new period. The previous period stays as recorded.")
            }
        case .newPeriod, .period:
            Section {
                RecordDateFields(draft: $start)
            } header: {
                MHSectionHeader("Start")
            }
            Section {
                Toggle("Ongoing", isOn: $ongoing)
                if !ongoing {
                    RecordDateFields(draft: $end)
                }
            } header: {
                MHSectionHeader("End")
            } footer: {
                MHSectionFooter("An ended period can have an unknown end date.")
            }
        }
    }

    private var recordForm: some View {
        Form {
            MHContainerContent {
                recordFields
                switch selection {
                case .mark, .period:
                    Section {
                        StallyActionButton(.deleteRecord, role: .destructive) {
                            confirmingDelete = true
                        }
                    }
                default:
                    EmptyView()
                }
                if let errorMessage {
                    Text(errorMessage).mhTextStyle(.supporting, colorRole: .destructive)
                }
            }
        }
        .mhFormChrome(.content)
    }

    init(selection: Selection) {
        self.selection = selection
        var startValue: String?
        var endValue: String?
        var ongoingValue = true
        switch selection {
        case .newMark:
            startValue = RecordDateDraft.today
        case .mark(let mark):
            startValue = mark.localDateTime
        case .period(let period):
            startValue = period.startLocalDate
            endValue = period.endLocalDate
            ongoingValue = period.isOngoing
        case .newPeriod, .end, .resume:
            break
        }
        _start = State(initialValue: .init(startValue))
        _end = State(initialValue: .init(endValue))
        _ongoing = State(initialValue: ongoingValue)
        if case .mark = selection {
            _originalMark = State(initialValue: startValue)
        }
        if case .period = selection {
            _originalPeriod = State(initialValue: .init(
                start: startValue, end: endValue, isOngoing: ongoingValue
            ))
        }
    }

    private func save() {
        mutate {
            switch selection {
            case .newMark:
                try MarkOperations.add(to: item, localDateTime: start.value ?? "", context: context)
            case .mark(let mark):
                try correctMark(mark)
            case .end(let period):
                try PeriodOperations.end(period, on: end.value, today: RecordDateDraft.today, context: context)
            case .resume(let period):
                try PeriodOperations.resume(period, on: start.value, today: RecordDateDraft.today, context: context)
            case .newPeriod, .period:
                let input = PeriodInput(start: start.value, end: ongoing ? nil : end.value, isOngoing: ongoing)
                if case .period(let period) = selection {
                    guard let originalPeriod else {
                        throw RecordError.staleReview
                    }
                    try PeriodOperations.correct(
                        period,
                        input: input,
                        today: RecordDateDraft.today,
                        context: context,
                        original: originalPeriod
                    )
                } else {
                    try PeriodOperations.add(to: item, input: input, today: RecordDateDraft.today, context: context)
                }
            }
        }
    }

    private func correctMark(_ mark: ItemMark) throws {
        guard let originalMark else {
            throw RecordError.staleReview
        }
        try MarkOperations.correct(
            mark, localDateTime: start.value ?? "", context: context, original: originalMark
        )
    }

    private func deleteRecord() {
        mutate {
            switch selection {
            case .mark(let mark):
                try MarkOperations.delete(mark, context: context)
            case .period(let period):
                try PeriodOperations.delete(period, context: context)
            default:
                break
            }
        }
    }

    private func mutate(_ operation: @escaping () throws -> Void) {
        saving = true
        Task {
            defer {
                saving = false
            }
            do {
                try await writeSession.performMutation(operation)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
