import MHUI
import StallyLibrary
import SwiftUI

struct ItemPeriodReview: View {
    @Environment(\.dismiss)
    private var dismiss
    @State private var start: RecordDateDraft
    @State private var end: RecordDateDraft
    @State private var continuation: ItemPeriodSuggestion.Continuation
    let candidate: ItemPeriodSuggestion
    let onUse: (PeriodInput) -> Void

    var body: some View {
        NavigationStack {
            periodForm
                .mhFormChrome(.content)
                .environment(\.calendar, RecordDateDraft.calendar)
                .environment(\.timeZone, RecordDateDraft.calendar.timeZone)
                .navigationTitle("Review Period")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        StallyActionButton(.cancel) {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Use Period") {
                            onUse(.init(
                                start: start.value,
                                end: continuation == .ongoing ? nil : end.value,
                                isOngoing: continuation == .ongoing
                            ))
                            dismiss()
                        }
                        .disabled(continuation == .unspecified)
                    }
                }
        }
    }

    private var periodForm: some View {
        Form {
            MHContainerContent {
                sourceSection
                Section {
                    RecordDateFields(draft: $start)
                } header: {
                    MHSectionHeader("Start")
                }
                Section {
                    Picker("Period Status", selection: $continuation) {
                        ForEach(ItemPeriodSuggestion.Continuation.allCases) { value in
                            if value == .unspecified {
                                Text("Choose…").tag(value)
                            } else {
                                Text(value.title).tag(value)
                            }
                        }
                    }
                    if continuation == .ended {
                        RecordDateFields(draft: $end)
                    }
                } header: {
                    MHSectionHeader("End")
                } footer: {
                    Text("An unknown end date does not mean ongoing. Choose the status before using this period.")
                }
            }
        }
    }

    @ViewBuilder private var sourceSection: some View {
        if !candidate.evidence.isEmpty {
            Section {
                LabeledContent("Date Meaning", value: candidate.basis.title)
                Text(candidate.evidence)
                    .textSelection(.enabled)
            } header: {
                MHSectionHeader("Source Passage")
            } footer: {
                Text("Choose which date marks the start of your relationship with this Item.")
            }
        }
    }

    init(candidate: ItemPeriodSuggestion, reviewed: PeriodInput?, onUse: @escaping (PeriodInput) -> Void) {
        self.candidate = candidate
        self.onUse = onUse
        _start = .init(initialValue: .init(reviewed.map(\.start) ?? candidate.start))
        _end = .init(initialValue: .init(reviewed.map(\.end) ?? candidate.end))
        _continuation = .init(initialValue: reviewed.map { $0.isOngoing ? .ongoing : .ended } ?? candidate.continuation)
    }
}

#Preview("Review Purchase Month") {
    ItemPeriodReview(candidate: .init(
        start: "2023-06",
        end: nil,
        continuation: .unspecified,
        basis: .purchase,
        evidence: "2023年6月に青いマグを購入。購入日は覚えていない。"
    ),
    reviewed: nil
    ) { _ in
        // Preview only stages a value; no records are saved.
    }
}
