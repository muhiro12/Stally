#if DEBUG
import Foundation

/// Local development preferences, never read by Release startup.
public enum StallyDevelopmentPreferences {
    /// Whether a newly created local development directory receives representative records.
    public static let automaticallySeedRecordsKey = "development.automaticallySeedRecords"
    /// Explicitly selects the shared CloudKit store on the next DEBUG launch.
    public static let useSharedStoreKey = "development.useSharedStore"

    /// Registration supplies defaults without replacing saved choices or launch overrides.
    public static func register(in defaults: UserDefaults = .standard) {
        defaults.register(defaults: [automaticallySeedRecordsKey: true, useSharedStoreKey: false])
    }
}
#endif
