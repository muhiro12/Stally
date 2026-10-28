import StallyLibrary
import SwiftData
import SwiftUI

struct TagEditor: View {
    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.modelContext)
    private var context
    @Environment(RemoteUpdateOperations.self)
    private var updates
    @Query(sort: \Tag.name)
    private var tags: [Tag]
    let tag: Tag?
    @State private var name: String
    @State private var saving = false
    @State private var confirmingDelete = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            tagForm
                .disabled(saving)
                .navigationTitle(tag == nil ? "Add Tag" : "Edit Tag")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", systemImage: "xmark") {
                            dismiss()
                        }.disabled(saving)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save", systemImage: "checkmark", action: save)
                            .disabled(saving || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .interactiveDismissDisabled(saving)
                .confirmationDialog("Delete this tag and its assignments?", isPresented: $confirmingDelete) {
                    Button("Delete Tag", role: .destructive) {
                        if let tag {
                            mutate {
                                try TagOperations.delete(tag, context: context)
                            }
                        }
                    }
                }
        }
    }

    private var tagForm: some View {
        Form {
            Section {
                TextField("Name", text: $name)
            } footer: {
                if tags.contains(where: { candidate in
                    candidate !== tag && candidate.name.localizedStandardCompare(name) == .orderedSame
                }) {
                    Text("A similar tag already exists. Saving keeps these tags separate.")
                }
            }
            if tag != nil {
                Section {
                    Button("Delete Tag", role: .destructive) {
                        confirmingDelete = true
                    }
                } footer: {
                    Text("Deleting a tag removes its assignments. Your Items and records stay.")
                }
            }
            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red)
            }
        }
    }

    init(tag: Tag?) {
        self.tag = tag
        _name = State(initialValue: tag?.name ?? "")
    }

    private func save() {
        mutate {
            if let tag {
                try TagOperations.rename(tag, name: name, context: context)
            } else {
                try TagOperations.create(name: name, context: context)
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
                try await updates.performMutation(operation)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
