/// High-level counts derived from a backup snapshot preview.
public struct StallyBackupImportAnalysisSummary: Equatable, Sendable {
    /// Total number of items contained in the snapshot.
    public let totalItems: Int

    /// Number of archived items in the snapshot.
    public let archivedItems: Int

    /// Total number of marks contained in the snapshot.
    public let totalMarks: Int

    /// Number of snapshot items that already exist locally.
    public let existingItems: Int

    /// Number of snapshot items that would be new locally.
    public let newItems: Int

    /// Creates an import summary.
    public init(
        totalItems: Int,
        archivedItems: Int,
        totalMarks: Int,
        existingItems: Int,
        newItems: Int
    ) {
        self.totalItems = totalItems
        self.archivedItems = archivedItems
        self.totalMarks = totalMarks
        self.existingItems = existingItems
        self.newItems = newItems
    }
}
