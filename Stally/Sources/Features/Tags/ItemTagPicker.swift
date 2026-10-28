import MHUI
import StallyLibrary
import SwiftData
import SwiftUI

struct ItemTagPicker: View {
    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.modelContext)
    private var context
    @Environment(RemoteUpdateOperations.self)
    private var updates
    @Query(sort: \Tag.name)
    private var tags: [Tag]
    let item: Item
    @State private var selectedIDs: Set<PersistentIdentifier>
    @State private var addingTag = false
    @State private var saving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            tagList
                .disabled(saving)
                .navigationTitle("Choose Tags")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", systemImage: "xmark") {
                            dismiss()
                        }.disabled(saving)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save", systemImage: "checkmark", action: save).disabled(saving)
                    }
                }
                .interactiveDismissDisabled(saving)
                .sheet(isPresented: $addingTag) {
                    TagEditor(tag: nil)
                }
        }
    }

    private var tagList: some View {
        List {
            MHContainerContent {
                Section {
                    ForEach(tags) { tag in
                        Toggle(isOn: binding(for: tag)) {
                            TagNameView(tag: tag, tags: tags)
                        }
                    }
                    Button("Add Tag", systemImage: "plus") {
                        addingTag = true
                    }
                } footer: {
                    MHSectionFooter("Choose the tags for this Item. Names alone never combine tags.")
                }
                if let errorMessage {
                    Text(errorMessage).mhTextStyle(.supporting, colorRole: .destructive)
                }
            }
        }
        .mhListChrome(.content)
    }

    init(item: Item) {
        self.item = item
        _selectedIDs = State(initialValue: Set((item.tags ?? []).map(\.persistentModelID)))
    }

    private func binding(for tag: Tag) -> Binding<Bool> {
        .init(
            get: {
                selectedIDs.contains(tag.persistentModelID)
            },
            set: { selected in
                if selected {
                    selectedIDs.insert(tag.persistentModelID)
                } else {
                    selectedIDs.remove(tag.persistentModelID)
                }
            })
    }

    private func save() {
        saving = true
        Task {
            defer {
                saving = false
            }
            do {
                try await updates.performMutation {
                    try TagOperations.assign(
                        tags.filter { tag in
                            selectedIDs.contains(tag.persistentModelID)
                        },
                        to: item,
                        context: context
                    )
                }
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
