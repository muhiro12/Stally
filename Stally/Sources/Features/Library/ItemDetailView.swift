import MHUI
import StallyLibrary
import SwiftData
import SwiftUI

struct ItemDetailView: View {
    @Environment(\.modelContext)
    private var context
    @Environment(RecordWriteSession.self)
    private var writeSession
    let item: Item
    let onDelete: () -> Void
    @State private var editingItem = false
    @State private var choosingTags = false
    @State private var editingRecord: RecordEditor.Selection?
    @State private var selectedPhoto: ItemDraft.Photo?
    @State private var confirmingDelete = false
    @State private var errorMessage: String?
    @State private var saving = false

    var body: some View {
        List {
            MHContainerContent {
                ItemSummarySection(item: item) {
                    choosingTags = true
                }
                ItemPhotosSection(item: item) { photo in
                    selectedPhoto = photo
                }
                PeriodReadingsSection(item: item)
                ItemMarksSection(item: item) { selection in
                    editingRecord = selection
                }
                ItemPeriodsSection(item: item) { selection in
                    editingRecord = selection
                }
                Section {
                    Toggle("Mark Recording", isOn: recordingBinding)
                } footer: {
                    MHSectionFooter("Pausing stops new Marks. Your existing records and periods stay unchanged.")
                }
            }
        }
        .mhListChrome(.content)
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
        .sheet(item: $selectedPhoto) { photo in
            PhotoDetailView(photo: photo)
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
        ToolbarItem(placement: LibraryLayout.primaryActionPlacement) {
            Button("Edit Item", systemImage: "square.and.pencil") {
                editingItem = true
            }
            .disabled(saving)
        }
        #if os(iOS) || os(visionOS)
        ToolbarOverflowMenu {
            itemActions
        }
        #else
        ToolbarItem(placement: .primaryAction) {
            Menu("Item Actions", systemImage: "ellipsis") {
                itemActions
            }
            .disabled(saving)
        }
        #endif
    }

    private var itemActions: some View {
        Group {
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
            ShareLink(item: StallyLinkOperations.url(for: .item(item.uuid))) {
                Label("Share Item Link", systemImage: "square.and.arrow.up")
            }
            Divider()
            Button("Delete Item", systemImage: "trash", role: .destructive) {
                confirmingDelete = true
            }
        }
        .disabled(saving)
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
            }
        )
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
            }
        )
    }

    private func mutate(_ operation: @escaping () throws -> Void) {
        saving = true
        Task {
            defer {
                saving = false
            }
            do {
                try await writeSession.performMutation(operation)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
