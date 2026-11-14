/// Persisted domain and portable-envelope versions evolve independently.
public enum StallyDataContract {
    /// Matches StallySchema, independently of the app release number.
    public static let schemaVersion = StallySchema.versionIdentifier.description
    /// First published package envelope, paired with the selected schema by the codec.
    public static let formatVersion = 1
    /// Shared package type and JSON envelope discriminator for the first release.
    public static let fileTypeIdentifier = "com.muhiro12.Stally.data"

    static let manifestFilename = "manifest.json"
    static let assetDirectory = "assets"
    static let assetPathPrefix = assetDirectory + "/"
}
