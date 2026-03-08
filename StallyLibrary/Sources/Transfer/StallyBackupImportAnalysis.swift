/// Previewable validation result for one import snapshot.
public struct StallyBackupImportAnalysis: Equatable, Sendable {
    /// Snapshot being analyzed.
    public let snapshot: StallyBackupSnapshot

    /// High-level counts derived from the snapshot.
    public let summary: StallyBackupImportAnalysisSummary

    /// Validation issues discovered during analysis.
    public let issues: [StallyBackupImportIssue]

    /// Issues that block import.
    public var errors: [StallyBackupImportIssue] {
        issues.filter { $0.severity == .error }
    }

    /// Non-blocking issues worth surfacing before import.
    public var warnings: [StallyBackupImportIssue] {
        issues.filter { $0.severity == .warning }
    }

    /// Indicates whether import can proceed.
    public var canImport: Bool {
        errors.isEmpty
    }

    /// Creates an import analysis.
    public init(
        snapshot: StallyBackupSnapshot,
        summary: StallyBackupImportAnalysisSummary,
        issues: [StallyBackupImportIssue]
    ) {
        self.snapshot = snapshot
        self.summary = summary
        self.issues = issues
    }
}
