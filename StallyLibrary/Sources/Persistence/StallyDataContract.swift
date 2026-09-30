/// The explicit correspondence between persisted and portable durable data.
public enum StallyDataContract {
    private static let legacyInterchangeVersion = 2
    private static let legacyPersistenceVersion = 1
    /// Current SwiftData schema: Items with independent Mark policy and partial starts.
    public static let persistenceVersion = 2
    /// The equivalent portable representation, retaining the development file sequence.
    public static let interchangeVersion = 3

    /// Returns the persisted contract represented by a supported portable version.
    public static func persistenceVersion(forInterchangeVersion version: Int) -> Int? {
        switch version {
        case legacyInterchangeVersion:
            legacyPersistenceVersion
        case interchangeVersion:
            persistenceVersion
        default:
            nil
        }
    }
}
