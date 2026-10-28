import StallyLibrary
import SwiftData
import SwiftUI

struct ItemEditor: View {
    @Environment(\.modelContext)
    private var context
    @Environment(\.dismiss)
    private var dismiss
    @Environment(RemoteUpdateOperations.self)
    private var updates
    let item: Item?
    let onSave: ((Item) -> Void)?
    @State private var name: String
    @State private var note: String
    @State private var errorMessage: String?
    @State private var saving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Name", text: $name)
                }
                Section("Note") {
                    TextField("What would you like to remember?", text: $note, axis: .vertical)
                        .lineLimit(LibraryLayout.noteLines)
                }
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
            .disabled(saving)
            .interactiveDismissDisabled(saving)
            .navigationTitle(item == nil ? "Add Item" : "Edit Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") {
                        dismiss()
                    }.disabled(saving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", systemImage: "checkmark") {
                        save()
                    }
                    .disabled(saving || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    init(item: Item?, onSave: ((Item) -> Void)?) {
        self.onSave = onSave
        self.item = item
        _name = State(initialValue: item?.name ?? "")
        _note = State(initialValue: item?.note ?? "")
    }

    private func save() {
        saving = true
        Task {
            defer {
                saving = false
            }
            do {
                try await updates.performMutation {
                    if let item {
                        try ItemOperations.update(item, name: name, note: note, context: context)
                        onSave?(item)
                    } else {
                        let created = try ItemOperations.create(context: context, name: name, note: note)
                        onSave?(created)
                    }
                }
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
