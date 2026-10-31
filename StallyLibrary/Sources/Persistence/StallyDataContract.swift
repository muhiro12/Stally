/// Persisted domain and portable-envelope versions evolve independently.
public enum StallyDataContract {
    /// Matches StallySchema, independently of the app release number.
    public static let schemaVersion = StallySchema.versionIdentifier.description
    /// First published package envelope, paired with the selected schema by the codec.
    public static let formatVersion = 1
    /// Selected package identity, distinct from the old flat development file.
    public static let fileTypeIdentifier = "com.muhiro12.stally.export"
}
