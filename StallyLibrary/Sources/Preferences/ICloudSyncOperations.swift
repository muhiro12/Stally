import MHPlatformCore

/// Keeps the person's sync choice independent of subscription access.
public enum ICloudSyncOperations {
    /// Verification state reported by the subscription provider.
    public enum SubscriptionAccess: Sendable {
        case unknown
        case inactive
        case active
    }

    /// Updates startup evidence without changing the saved sync choice.
    public static func updateSubscriptionAccess(
        _ access: SubscriptionAccess,
        store: MHPreferenceStore = .init()
    ) {
        switch access {
        case .unknown:
            return
        case .inactive:
            store.set(false, for: \.stallySubscriptionActive)
        case .active:
            store.set(true, for: \.stallySubscriptionActive)
        }
    }

    /// Resolves the next process's configuration, not the currently open store's state.
    public static func isEnabled(store: MHPreferenceStore = .init()) -> Bool {
        store.bool(for: \.stallyICloudEnabled) && store.bool(for: \.stallySubscriptionActive)
    }
}
