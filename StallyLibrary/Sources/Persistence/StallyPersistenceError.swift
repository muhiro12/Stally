import Foundation

/// Startup failures preserve the original store instead of opening an empty replacement.
public enum StallyPersistenceError: LocalizedError {
    case appGroupUnavailable
    case developmentStoreRequiresReview(URL)

    public var errorDescription: String? {
        switch self {
        case .appGroupUnavailable:
            String(
                localized:
                    "The shared Stally container is unavailable. Check App Group signing and reopen Stally.",
                bundle: .module
            )
        case .developmentStoreRequiresReview(let url):
            String(
                localized:
                    "An earlier development store needs review before Stally can open. No data was moved or deleted.",
                bundle: .module
            ) + "\n" + url.path
        }
    }
}
