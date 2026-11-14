import AppIntents

enum PeriodContinuationChange: String, AppEnum {
    case unchanged
    case ongoing
    case ended

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Continuation")
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .unchanged: "Keep Current State",
        .ongoing: "Ongoing",
        .ended: "Ended"
    ]

    func applying(to isOngoing: Bool) -> Bool {
        switch self {
        case .unchanged:
            isOngoing
        case .ongoing:
            true
        case .ended:
            false
        }
    }
}
