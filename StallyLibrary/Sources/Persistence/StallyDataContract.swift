/// Persisted domain and portable-envelope versions evolve independently.
public enum StallyDataContract {
    /// Matches StallySchema, independently of the app release number.
    public static let schemaVersion = "1.0.0"
    /// Reserved version for the selected package envelope; the codec is not implemented yet.
    public static let formatVersion = 1
    /// Selected package identity, distinct from the old flat development file.
    public static let fileTypeIdentifier = "com.muhiro12.stally.export"
}
