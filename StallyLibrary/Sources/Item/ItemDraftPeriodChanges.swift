import Foundation
import SwiftData

/// Resolves only the submitted period changes against current history in the Item's writer.
struct ItemDraftPeriodChanges {
    private var corrections: [(ItemPeriod, PeriodInput)] = []
    private var deletions: [ItemPeriod] = []
    private var additions: [ItemDraft.Period] = []

    init(_ draft: ItemDraft, item: Item, today: String?, context: ModelContext) throws {
        let original = draft.original?.periods ?? []
        guard draft.periods != original else {
            return
        }

        let submitted = try RecordMutation.index(draft.periods, identity: \.id)
        let baseline = try RecordMutation.index(original, identity: \.id)
        let saved = try RecordMutation.index(item.periods ?? [], identity: \.uuid).mapValues(PeriodInput.init)
        var final = saved
        for period in original where submitted[period.id]?.input != period.input {
            let record = try PeriodOperations.period(uuid: period.id, context: context)
            guard record.item === item, saved[period.id] == period.input else {
                throw RecordError.staleReview
            }
            final[period.id] = submitted[period.id]?.input
            if let input = submitted[period.id]?.input {
                corrections.append((record, input))
            } else {
                deletions.append(record)
            }
        }
        for period in draft.periods where baseline[period.id] == nil {
            guard period.isNew, final[period.id] == nil else {
                throw RecordError.ambiguousIdentity
            }
            final[period.id] = period.input
            additions.append(period)
        }
        try validate(saved: saved, final: final, today: today)
    }

    private func validate(saved: [UUID: PeriodInput], final: [UUID: PeriodInput], today: String?) throws {
        guard !corrections.isEmpty || !additions.isEmpty else {
            return
        }
        guard let today else {
            throw RecordError.invalidPeriod
        }
        for (record, input) in corrections {
            try PeriodOperations.validateCorrection(
                input,
                siblings: final.filter { $0.key != record.uuid },
                original: .init(record),
                originalSiblings: saved.filter { $0.key != record.uuid },
                today: today
            )
        }
        for period in additions {
            let siblings = final.filter { $0.key != period.id }.values
            if period.isReviewedSuggestion, siblings.contains(period.input) {
                throw RecordError.invalidPeriod
            }
            try PeriodOperations.validateInput(period.input, siblings: Array(siblings), today: today)
        }
    }

    func apply(to item: Item, context: ModelContext) {
        for record in deletions {
            context.delete(record)
        }
        for (record, input) in corrections {
            record.startLocalDate = input.start
            record.endLocalDate = input.end
            record.isOngoing = input.isOngoing
        }
        for period in additions {
            let input = period.input
            context.insert(ItemPeriod(
                item: item, startLocalDate: input.start, endLocalDate: input.end, isOngoing: input.isOngoing
            ))
        }
    }
}
