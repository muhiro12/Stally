import MHUI
import StallyLibrary
import SwiftData
import SwiftUI

struct ImportReviewView: View {
    @Environment(\.modelContext)
    private var context
    @Environment(RemoteUpdateOperations.self)
    private var updates
    @Environment(\.dismiss)
    private var dismiss
    let review: TransferReview
    let completed: (Int) -> Void
    @State private var selection: Set<UUID>
    @State private var errorMessage: String?
    @State private var saving = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(
                        "New records may restore deleted records. Deselect anything you do not want to add."
                    )
                    Text("Choosing a file value replaces that record's fields. Other records stay unchanged.")
                }
                ForEach(review.rows) { row in
                    ImportReviewRow(review: review, row: row, selected: binding(row.id))
                }
                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            }
            .disabled(saving)
            .navigationTitle("Review Import")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.disabled(saving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import Selected", action: save).disabled(saving || selection.isEmpty)
                }
            }
        }
        .interactiveDismissDisabled(saving)
    }

    init(review: TransferReview, completed: @escaping (Int) -> Void) {
        self.review = review
        self.completed = completed
        _selection = State(initialValue: review.defaultSelection)
    }

    private func binding(_ uuid: UUID) -> Binding<Bool> {
        .init(
            get: { selection.contains(uuid) },
            set: { included in
                if included { selection.insert(uuid) } else { selection.remove(uuid) }
            }
        )
    }

    private func save() {
        saving = true
        Task {
            defer { saving = false }
            do {
                let count = try await updates.performMutation {
                    try TransferOperations.apply(
                        review,
                        selection: selection,
                        today: MarkOperations.localDateTime(at: .now, includesTime: false),
                        context: context
                    )
                }
                completed(count)
            } catch { errorMessage = error.localizedDescription }
        }
    }
}
