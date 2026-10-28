import StallyLibrary
import SwiftData
import SwiftUI

struct ItemDetailView: View {
    @Environment(\.modelContext)
    private var context
    @Environment(RemoteUpdateOperations.self)
    private var updates
    let item: Item
    let onDelete: () -> Void
    @State private var editingItem = false
    @State private var choosingTags = false
    @State private var editingRecord: RecordEditor.Selection?
    @State private var confirmingDelete = false
    @State private var errorMessage: String?
    @State private var saving = false

    var body: some View {
        List {
            ItemSummarySection(item: item) {
                choosingTags = true
            }
            ItemMarksSection(item: item) { selection in
                editingRecord = selection
            }
            ItemPeriodsSection(item: item) { selection in
                editingRecord = selection
            }
            Section {
                Toggle("Mark Recording", isOn: recordingBinding)
            } footer: {
                Text("Pausing stops new Marks. Your existing records and periods stay unchanged.")
            }
        }
        .disabled(saving)
        .navigationTitle(item.name)
        .toolbar { itemToolbar }
        .sheet(isPresented: $editingItem) {
            ItemEditor(item: item, onSave: nil)
        }
        .sheet(isPresented: $choosingTags) {
            ItemTagPicker(item: item)
        }
        .sheet(item: $editingRecord) { selection in
            RecordEditor(item: item, selection: selection)
        }
        .confirmationDialog(
            "Delete this Item and its Marks, periods, and photos?",
            isPresented: $confirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete Item", role: .destructive) {
                mutate {
                    try ItemOperations.delete(item, context: context)
                    onDelete()
                }
            }
        }
        .alert("Could Not Save", isPresented: showingError) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @ToolbarContentBuilder private var itemToolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button("Edit Item", systemImage: "square.and.pencil") {
                editingItem = true
            }
            .disabled(saving)
        }
        ToolbarItem(placement: .primaryAction) {
            Menu("Item Actions", systemImage: "ellipsis") {
                Button(
                    item.isFavorite ? "Remove Favorite" : "Add to Favorites",
                    systemImage: item.isFavorite ? "star.slash" : "star"
                ) {
                    mutate {
                        try ItemOperations.setFavorite(item, to: !item.isFavorite, context: context)
                    }
                }
                Button(
                    item.isArchived ? "Move to Library" : "Archive Item",
                    systemImage: item.isArchived ? "tray.and.arrow.up" : "archivebox"
                ) {
                    mutate {
                        try ItemOperations.setArchived(item, to: !item.isArchived, context: context)
                    }
                }
                Button("Choose Tags", systemImage: "tag") {
                    choosingTags = true
                }
                Divider()
                Button("Delete Item", systemImage: "trash", role: .destructive) {
                    confirmingDelete = true
                }
            }
            .disabled(saving)
        }
    }

    private var showingError: Binding<Bool> {
        .init(
            get: {
                errorMessage != nil
            },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            })
    }

    private var recordingBinding: Binding<Bool> {
        .init(
            get: {
                item.isMarkRecordingEnabled
            },
            set: { value in
                mutate {
                    try ItemOperations.setMarkRecordingEnabled(item, to: value, context: context)
                }
            })
    }

    private func mutate(_ operation: @escaping () throws -> Void) {
        saving = true
        Task {
            defer {
                saving = false
            }
            do {
                try await updates.performMutation(operation)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
