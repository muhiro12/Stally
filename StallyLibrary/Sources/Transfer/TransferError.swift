import Foundation

/// A rejected transfer never changes the library.
public enum TransferError: LocalizedError {
    case invalidFile
    case unsupportedVersion
    case limitExceeded
    case incompleteGraph
    case staleReview
    case invalidSelection

    public var errorDescription: String? {
        switch self {
        case .invalidFile:
            String(localized: "The file is incomplete, damaged, or is not a Stally export.", bundle: .module)
        case .unsupportedVersion:
            String(localized: "This export version is not supported by this app.", bundle: .module)
        case .limitExceeded:
            String(localized: "This transfer exceeds the supported size limits.", bundle: .module)
        case .incompleteGraph:
            String(
                localized: "Resolve missing relationships or conflicting identities before transferring.",
                bundle: .module
            )
        case .staleReview:
            String(localized: "The library changed. Review the import again before saving.", bundle: .module)
        case .invalidSelection:
            String(localized: "Include the required Items and Tags, and resolve conflicting periods.", bundle: .module)
        }
    }
}
