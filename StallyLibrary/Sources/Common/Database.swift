import Foundation

/// Shared database locations used by the Stally app.
public enum Database {
    /// Current SQLite store URL inside Application Support.
    public static let url = URL.applicationSupportDirectory.appendingPathComponent(fileName)

    static let fileName = "Stally.sqlite"
}
