import MHUI
import StallyLibrary
import SwiftUI

struct ItemInputAssistView: View {
    private static let sourceLines = 5...12
    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.locale)
    private var locale
    @Environment(\.scenePhase)
    private var scenePhase
    @State private var source = ""
    @State private var suggestion: ItemInputSuggestion?
    @State private var requestID: UUID?
    @State private var errorMessage: String?
    @State private var unavailableReason: ItemInputError?
    let onApply: (ItemInputSuggestion) -> Void

    var body: some View {
        NavigationStack {
            Form {
                MHContainerContent {
                    sourceSection
                    if let suggestion {
                        reviewSection(suggestion)
                    }
                    if let errorMessage {
                        Section {
                            Text(errorMessage)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .mhFormChrome(.content)
            .navigationTitle("Input Assistance")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    StallyActionButton(.cancel) {
                        requestID = nil
                        dismiss()
                    }
                }
            }
        }
        .task(id: requestID) {
            guard let requestID else {
                return
            }
            await generate(requestID: requestID)
        }
        .onAppear(perform: refreshAvailability)
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                refreshAvailability()
            }
        }
        .onChange(of: source) {
            suggestion = nil
            errorMessage = nil
        }
    }

    private var sourceSection: some View {
        Section {
            TextField("Describe one thing or place, or paste its details.", text: $source, axis: .vertical)
                .lineLimit(Self.sourceLines)
                .disabled(requestID != nil)
            if requestID != nil {
                ProgressView("Preparing Suggestion…")
                Button("Stop", role: .cancel) {
                    requestID = nil
                }
            } else {
                Button("Prepare Suggestion", systemImage: "sparkles") {
                    refreshAvailability()
                    errorMessage = nil
                    suggestion = nil
                    requestID = UUID()
                }
                .disabled(source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || unavailableReason != nil)
            }
            if let unavailableReason {
                Text(unavailableReason.localizedDescription)
                    .foregroundStyle(.secondary)
            }
        } header: {
            MHSectionHeader("Description")
        } footer: {
            Text("""
                Apple Intelligence uses this text on your device to suggest a name, note, and link. \
                Review the result before using it. You can also enter fields manually.
                """)
        }
    }

    private func reviewSection(_ suggestion: ItemInputSuggestion) -> some View {
        Section {
            LabeledContent("Name", value: suggestion.name)
            if !suggestion.note.isEmpty {
                LabeledContent("Note", value: suggestion.note)
            }
            if !suggestion.representativeURL.isEmpty {
                LabeledContent("Link", value: suggestion.representativeURL)
            }
            Button("Fill Empty Fields", systemImage: "text.badge.plus") {
                onApply(suggestion)
                dismiss()
            }
        } header: {
            MHSectionHeader("Suggestion")
        } footer: {
            Text("""
                Only empty fields will be filled. You can edit them before saving the Item. \
                Marks and periods are not added.
                """)
        }
    }

    private func refreshAvailability() {
        unavailableReason = ItemInputOperations.unavailableReason(locale: locale)
    }

    private func generate(requestID: UUID) async {
        do {
            let result = try await ItemInputOperations.infer(text: source, locale: locale)
            guard !Task.isCancelled, self.requestID == requestID else {
                return
            }
            suggestion = result
        } catch {
            guard !Task.isCancelled, self.requestID == requestID else {
                return
            }
            if !(error is CancellationError) {
                errorMessage = error.localizedDescription
            }
        }
        if self.requestID == requestID {
            self.requestID = nil
        }
    }
}

#Preview {
    ItemInputAssistView { _ in
        // Preview does not apply suggestions to a saved record.
    }
}
