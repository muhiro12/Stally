import MHUI
import StallyLibrary
import SwiftUI

struct ItemInputAssistView: View {
    private struct PeriodSelection: Identifiable {
        let id: Int
        let candidate: ItemPeriodSuggestion
    }

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
    @State private var reviewedPeriods: [Int: PeriodInput] = [:]
    @State private var reviewingPeriod: PeriodSelection?
    @State private var overwriteExistingText = false
    let onApply: (ItemInputSuggestion, [PeriodInput], Bool) -> Void

    var body: some View {
        NavigationStack {
            Form {
                MHContainerContent {
                    sourceSection
                    if let suggestion {
                        reviewSection(suggestion)
                        periodSection(suggestion)
                        applySection(suggestion)
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
            reviewedPeriods = [:]
            reviewingPeriod = nil
        }
        .sheet(item: $reviewingPeriod) { selection in
            ItemPeriodReview(candidate: selection.candidate, reviewed: reviewedPeriods[selection.id]) { period in
                reviewedPeriods[selection.id] = period
            }
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
                    reviewedPeriods = [:]
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
                Apple Intelligence uses this text on your device to suggest Item details and periods. \
                Review the result before using it. You can also enter fields manually.
                """)
        }
    }

    init(onApply: @escaping (ItemInputSuggestion, [PeriodInput], Bool) -> Void) {
        self.onApply = onApply
    }

    init(
        source: String,
        suggestion: ItemInputSuggestion,
        onApply: @escaping (ItemInputSuggestion, [PeriodInput], Bool) -> Void
    ) {
        self.onApply = onApply
        _source = .init(initialValue: source)
        _suggestion = .init(initialValue: suggestion)
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
        } header: {
            MHSectionHeader("Suggestion")
        }
    }

    @ViewBuilder
    private func periodSection(_ suggestion: ItemInputSuggestion) -> some View {
        if !suggestion.periods.isEmpty {
            Section {
                ForEach(Array(suggestion.periods.enumerated()), id: \.offset) { index, candidate in
                    Button {
                        reviewingPeriod = .init(id: index, candidate: candidate)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(candidate.basis.title)
                            Text(RecordDateDraft.display(reviewedPeriods[index].map(\.start) ?? candidate.start))
                                .mhRowSupporting()
                            if reviewedPeriods[index] != nil {
                                Label("Ready to Add", systemImage: "checkmark.circle")
                            } else {
                                Text("Review Period").mhRowSupporting()
                            }
                        }
                    }
                    if reviewedPeriods[index] != nil {
                        Button("Skip This Period", role: .destructive) {
                            reviewedPeriods[index] = nil
                        }
                    }
                }
            } header: {
                MHSectionHeader("Suggested Periods")
            } footer: {
                Text("Review each period you want to add. Purchase, order, and delivery dates may be alternatives.")
            }
        }
    }

    private func applySection(_ suggestion: ItemInputSuggestion) -> some View {
        Section {
            Toggle("Replace Existing Text", isOn: $overwriteExistingText)
            Button("Use Suggestion", systemImage: "text.badge.plus") {
                onApply(
                    suggestion, reviewedPeriods.keys.sorted().compactMap { reviewedPeriods[$0] }, overwriteExistingText
                )
                dismiss()
            }
        } footer: {
            Text("""
                Text fills empty fields unless you choose to replace existing text. \
                Missing details keep their current values. Only periods you reviewed are added. \
                You can edit the draft before saving the Item.
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
    ItemInputAssistView { _, _, _ in
        // Preview does not apply suggestions to a saved record.
    }
}

#Preview("Review Suggestions") {
    ItemInputAssistView(
        source: "青いマグ。2023年6月に購入。",
        suggestion: .init(name: "青いマグ", note: "2023年6月に購入。", periods: [
            .init(
                start: "2023-06",
                end: nil,
                continuation: .unspecified,
                basis: .purchase,
                evidence: "2023年6月に購入。"
            )
        ])
    ) { _, _, _ in
        // Preview only displays a suggestion; no editor or store is changed.
    }
}
