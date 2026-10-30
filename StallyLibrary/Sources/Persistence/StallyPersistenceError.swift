import Foundation

/// Startup failures preserve the original store instead of opening an empty replacement.
public enum StallyPersistenceError: LocalizedError {
    case appGroupUnavailable

    public var errorDescription: String? {
        switch self {
        case .appGroupUnavailable:
            String(
                localized:
                    "The shared Stally container is unavailable. Check App Group signing and reopen Stally.",
                bundle: .module
            )
        }
    }
}
