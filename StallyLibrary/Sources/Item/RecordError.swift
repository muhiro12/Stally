import Foundation

/// Validation failures leave recorded facts and unrelated pending work unchanged.
public enum RecordError: LocalizedError, Equatable {
    case nameRequired
    case invalidDate
    case recordingPaused
    case invalidPeriod
    case overlappingPeriods
    case ongoingPeriodExists
    case missingRecord
    case ambiguousIdentity
    case pendingChanges
    case wrongContext
    case invalidPhoto
    case invalidURL
    case staleReview

    public var errorDescription: String? {
        switch self {
        case .nameRequired:
            String(localized: "Enter a name.", bundle: .module)
        case .invalidDate:
            String(localized: "Enter a valid Gregorian date with the stated precision.", bundle: .module)
        case .recordingPaused:
            String(localized: "Resume Mark recording before adding an occurrence.", bundle: .module)
        case .invalidPeriod:
            String(
                localized: "The period has inconsistent boundaries or continuation state.",
                bundle: .module
            )
        case .overlappingPeriods:
            String(localized: "These periods definitely overlap. Review their boundaries.", bundle: .module)
        case .ongoingPeriodExists:
            String(localized: "Review the existing ongoing period before starting another.", bundle: .module)
        case .missingRecord:
            String(localized: "This record is no longer available.", bundle: .module)
        case .ambiguousIdentity:
            String(
                localized: "More than one record has this identity. Review the conflicting records.",
                bundle: .module
            )
        case .pendingChanges:
            String(localized: "Finish the pending edit before starting another operation.", bundle: .module)
        case .wrongContext:
            String(localized: "Reload this record before editing it.", bundle: .module)
        case .invalidPhoto:
            String(
                localized: "This image is not a supported complete still image within the saved limits.",
                bundle: .module
            )
        case .staleReview:
            String(localized: "The records changed. Review this operation again before saving.", bundle: .module)
        case .invalidURL:
            String(localized: "Enter a complete website or app URL.", bundle: .module)
        }
    }
}
