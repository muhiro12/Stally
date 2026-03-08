/// Result of a completed backup import mutation.
public struct StallyBackupImportResult: Equatable, Sendable {
    /// Preview analysis that was validated before import.
    public let analysis: StallyBackupImportAnalysis

    /// Number of deleted items.
    public let deletedItems: Int

    /// Number of created items.
    public let createdItems: Int

    /// Number of updated items.
    public let updatedItems: Int

    /// Number of inserted marks.
    public let insertedMarks: Int

    /// Number of skipped marks.
    public let skippedMarks: Int

    /// Creates an import result.
    public init(
        analysis: StallyBackupImportAnalysis,
        deletedItems: Int,
        createdItems: Int,
        updatedItems: Int,
        insertedMarks: Int,
        skippedMarks: Int
    ) {
        self.analysis = analysis
        self.deletedItems = deletedItems
        self.createdItems = createdItems
        self.updatedItems = updatedItems
        self.insertedMarks = insertedMarks
        self.skippedMarks = skippedMarks
    }
}
