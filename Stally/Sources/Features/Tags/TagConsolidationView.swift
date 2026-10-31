import StallyLibrary
import SwiftData
import SwiftUI

struct TagConsolidationView: View {
    @Environment(\.modelContext)
    private var context
    @Environment(\.dismiss)
    private var dismiss
    @Environment(RemoteUpdateOperations.self)
    private var updates
    @Query(sort: \Tag.name)
    private var tags: [Tag]
    @State private var sourceID: UUID?
    @State private var survivorID: UUID?
    @State private var review: TagConsolidation?
    @State private var confirming = false
    @State private var saving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                tagPicker("Replace Tag", selection: $sourceID)
                tagPicker("Keep Tag", selection: $survivorID)
                Text("Affected Items will use the kept Tag. The replaced Tag will be deleted.")
                Button("Review Consolidation", action: prepareReview)
                    .disabled(sourceID == nil || survivorID == nil || sourceID == survivorID)
                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            }
            .disabled(saving)
            .navigationTitle("Consolidate Tags")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.disabled(saving) }
            }
            .confirmationDialog("Consolidate these Tags?", isPresented: $confirming, titleVisibility: .visible) {
                Button("Consolidate", role: .destructive, action: save)
            } message: {
                if let review {
                    Text(
                        "\(review.sourceName) → \(review.survivorName) (\(review.affectedItemIDs.count) Items)"
                    )
                }
            }
        }
        .interactiveDismissDisabled(saving)
    }

    private func tagPicker(_ title: LocalizedStringKey, selection: Binding<UUID?>) -> some View {
        Picker(title, selection: selection) {
            Text("Choose Tag").tag(nil as UUID?)
            ForEach(tags) { tag in
                VStack(alignment: .leading) {
                    TagNameView(tag: tag, tags: tags)
                    Text("\((tag.items ?? []).count) Items").font(.caption).foregroundStyle(.secondary)
                }
                .tag(Optional(tag.uuid))
            }
        }
        .pickerStyle(.navigationLink)
    }

    private func prepareReview() {
        do {
            guard let source = tags.first(where: { $0.uuid == sourceID }),
                  let survivor = tags.first(where: { $0.uuid == survivorID })
            else {
                return
            }
            review = try TagOperations.reviewConsolidation(source: source, survivor: survivor, context: context)
            confirming = true
        } catch { errorMessage = error.localizedDescription }
    }

    private func save() {
        guard let review else {
            return
        }
        saving = true
        Task {
            defer { saving = false }
            do {
                try await updates.performMutation { try TagOperations.consolidate(review, context: context) }
                dismiss()
            } catch { errorMessage = error.localizedDescription }
        }
    }
}
