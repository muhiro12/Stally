import MHUI
import StallyLibrary
import SwiftData
import SwiftUI

struct RecordEditor: View {
    enum Selection: Identifiable {
        case newMark
        case mark(ItemMark)

        var id: String {
            switch self {
            case .newMark:
                "newMark"
            case .mark(let mark):
                "mark-\(mark.persistentModelID)"
            }
        }

        var title: LocalizedStringResource {
            switch self {
            case .newMark:
                "Add Mark"
            case .mark:
                "Edit Mark"
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
    @State private var originalMark: String?
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
        Section {
            RecordDateFields(draft: $start, allowsPartialDate: false)
        } footer: {
            MHSectionFooter("Each Mark is a separate occurrence, even on the same day. Time is optional.")
        }
    }

    private var recordForm: some View {
        Form {
            MHContainerContent {
                recordFields
                if case .mark = selection {
                    Section {
                        StallyActionButton(.deleteRecord, role: .destructive) {
                            confirmingDelete = true
                        }
                    }
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
        switch selection {
        case .newMark:
            startValue = RecordDateDraft.today
        case .mark(let mark):
            startValue = mark.localDateTime
        }
        _start = State(initialValue: .init(startValue))
        if case .mark = selection {
            _originalMark = State(initialValue: startValue)
        }
    }

    private func save() {
        mutate {
            switch selection {
            case .newMark:
                try MarkOperations.add(to: item, localDateTime: start.value ?? "", context: context)
            case .mark(let mark):
                try correctMark(mark)
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
            if case .mark(let mark) = selection {
                try MarkOperations.delete(mark, context: context)
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
