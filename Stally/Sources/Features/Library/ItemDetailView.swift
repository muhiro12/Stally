import StallyLibrary
import SwiftData
import SwiftUI

struct ItemDetailView: View {
    @Environment(\.modelContext)
    private var context
    @Environment(\.dismiss)
    private var dismiss
    @Environment(RemoteUpdateOperations.self)
    private var updates
    let item: Item
    @State private var editingItem = false
    @State private var editingRecord: RecordEditor.Selection?
    @State private var confirmingDelete = false
    @State private var errorMessage: String?
    @State private var saving = false

    var body: some View {
        List {
            stateSection
            markSection
            periodSection
            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red)
            }
            Section {
                Button("Delete Item", role: .destructive) { confirmingDelete = true }
            }
        }
        .disabled(saving)
        .navigationTitle(item.name)
        .toolbar { Button("Edit") { editingItem = true } }
        .sheet(isPresented: $editingItem) { ItemEditor(item: item) }
        .sheet(item: $editingRecord) { selection in RecordEditor(item: item, selection: selection) }
        .confirmationDialog(
            "Delete this Item and its Marks, periods, and photos?",
            isPresented: $confirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete Item", role: .destructive) {
                mutate {
                    try ItemOperations.delete(item, context: context)
                    dismiss()
                }
            }
        }
    }

    private var stateSection: some View {
        Section {
            if !item.note.isEmpty { Text(item.note) }
            Toggle("Favorite", isOn: favoriteBinding)
            Toggle("Archived", isOn: archivedBinding)
            Toggle("Mark Recording", isOn: recordingBinding)
        }
    }

    private var markSection: some View {
        Section("Marks") {
            ForEach((item.marks ?? []).sorted { $0.localDateTime > $1.localDateTime }) { mark in
                Button(mark.localDateTime) { editingRecord = .mark(mark) }
            }
            Button("Add Mark", systemImage: "plus") { editingRecord = .newMark }
                .disabled(!item.isMarkRecordingEnabled)
        }
    }

    private var periodSection: some View {
        Section("Periods") {
            ForEach((item.periods ?? []).sorted { $0.createdAt < $1.createdAt }) { period in
                Button {
                    editingRecord = .period(period)
                } label: {
                    VStack(alignment: .leading) {
                        Text(period.startLocalDate ?? String(localized: "Unknown start"))
                        Text(
                            period.isOngoing
                                ? String(localized: "Ongoing")
                                : period.endLocalDate ?? String(localized: "Unknown end")
                        )
                        .foregroundStyle(.secondary)
                    }
                }
            }
            Button("Add Period", systemImage: "plus") { editingRecord = .newPeriod }
        }
    }

    private var favoriteBinding: Binding<Bool> {
        .init(
            get: { item.isFavorite },
            set: { value in
                mutate { try ItemOperations.setFavorite(item, to: value, context: context) }
            }
        )
    }

    private var archivedBinding: Binding<Bool> {
        .init(
            get: { item.isArchived },
            set: { value in
                mutate { try ItemOperations.setArchived(item, to: value, context: context) }
            }
        )
    }

    private var recordingBinding: Binding<Bool> {
        .init(
            get: { item.isMarkRecordingEnabled },
            set: { value in
                mutate { try ItemOperations.setMarkRecordingEnabled(item, to: value, context: context) }
            }
        )
    }

    private func mutate(_ operation: @escaping () throws -> Void) {
        saving = true
        Task {
            defer { saving = false }
            do { try await updates.performMutation(operation) } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
