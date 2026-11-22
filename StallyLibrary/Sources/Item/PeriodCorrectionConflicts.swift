import Foundation

/// Only conflicts involving the edited period can change; sibling identities allow comparison across staged edits.
struct PeriodCorrectionConflicts<Identity: Hashable> {
    private var ongoingSiblings: Set<Identity> = []
    private var overlaps: [Identity: DateInterval] = [:]

    init(input: PeriodInput, siblings: [Identity: PeriodInput], today: String) throws {
        let todayDate = try CivilDate.parse(today, formats: [CivilDate.dayLength: "yyyy-MM-dd"])
        let start = try CivilDate.range(input.start)
        let end = try CivilDate.range(input.end)
        try PeriodOperations.validateBoundaries(start: start, end: end, isOngoing: input.isOngoing)
        for (id, sibling) in siblings {
            let siblingStart = try CivilDate.range(sibling.start)
            let siblingEnd = try CivilDate.range(sibling.end)
            try PeriodOperations.validateBoundaries(
                start: siblingStart, end: siblingEnd, isOngoing: sibling.isOngoing
            )
            if input.isOngoing, sibling.isOngoing {
                ongoingSiblings.insert(id)
            }
            if let start, let siblingStart,
               let earliestEnd = input.isOngoing ? todayDate : end?.start,
               let siblingEarliestEnd = sibling.isOngoing ? todayDate : siblingEnd?.start {
                let overlapStart = max(CivilDate.latestDay(in: start), CivilDate.latestDay(in: siblingStart))
                let overlapEnd = min(earliestEnd, siblingEarliestEnd)
                if overlapStart < overlapEnd {
                    overlaps[id] = .init(start: overlapStart, end: overlapEnd)
                }
            }
        }
    }

    func isImprovement(over previous: Self) -> Bool {
        guard ongoingSiblings.isSubset(of: previous.ongoingSiblings) else {
            return false
        }
        var improved = ongoingSiblings != previous.ongoingSiblings || overlaps.count < previous.overlaps.count
        for (id, overlap) in overlaps {
            guard let original = previous.overlaps[id],
                  overlap.start >= original.start, overlap.end <= original.end else {
                return false
            }
            if overlap != original {
                improved = true
            }
        }
        return improved
    }
}
