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
    @State private var name: String
    @State private var note: String
    @State private var errorMessage: String?
    @State private var saving = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("Note", text: $note, axis: .vertical)
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
            .navigationTitle(item == nil ? "Add Item" : "Edit Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(saving)
                }
            }
        }
    }

    init(item: Item?) {
        self.item = item
        _name = State(initialValue: item?.name ?? "")
        _note = State(initialValue: item?.note ?? "")
    }

    private func save() {
        saving = true
        Task {
            defer { saving = false }
            do {
                try await updates.performMutation {
                    if let item {
                        try ItemOperations.update(item, name: name, note: note, context: context)
                    } else {
                        try ItemOperations.create(context: context, name: name, note: note)
                    }
                }
                dismiss()
            } catch { errorMessage = error.localizedDescription }
        }
    }
}
