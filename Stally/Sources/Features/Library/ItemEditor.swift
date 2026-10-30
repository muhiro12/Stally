import MHUI
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
    @State private var draft: ItemDraft
    @State private var loadingPhotos = false
    @State private var errorMessage: String?
    @State private var saving = false

    var body: some View {
        NavigationStack {
            itemForm
                .disabled(saving || loadingPhotos)
                .interactiveDismissDisabled(saving || loadingPhotos)
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
                        .disabled(cannotSave)
                    }
                }
                .alert("Could Not Save", isPresented: showingError) {
                    Button("OK", role: .cancel) {
                        errorMessage = nil
                    }
                } message: {
                    Text(errorMessage ?? "")
                }
        }
    }

    private var cannotSave: Bool {
        saving || loadingPhotos || draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var showingError: Binding<Bool> {
        .init(
            get: { errorMessage != nil },
            set: { presented in
                if !presented {
                    errorMessage = nil
                }
            }
        )
    }

    private var itemForm: some View {
        Form {
            MHContainerContent {
                Section {
                    TextField("Name", text: $draft.name)
                } header: {
                    MHSectionHeader("Item")
                }
                Section {
                    TextField("What would you like to remember?", text: $draft.note, axis: .vertical)
                        .lineLimit(LibraryLayout.noteLines)
                } header: {
                    MHSectionHeader("Note")
                }
                Section {
                    TextField("Website or App URL", text: $draft.representativeURL)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                    #endif
                } header: {
                    MHSectionHeader("Link")
                }
                ItemDraftTagsSection(draft: $draft)
                ItemDraftPhotosSection(draft: $draft, loading: $loadingPhotos, errorMessage: $errorMessage)
            }
        }
        .mhFormChrome(.content)
    }

    init(item: Item?, onSave: ((Item) -> Void)?) {
        self.onSave = onSave
        self.item = item
        _draft = State(initialValue: item.map(ItemOperations.draft) ?? .init())
    }

    private func save() {
        saving = true
        Task {
            defer {
                saving = false
            }
            do {
                try await updates.performMutation {
                    let saved = try ItemOperations.save(draft, context: context)
                    onSave?(saved)
                }
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
