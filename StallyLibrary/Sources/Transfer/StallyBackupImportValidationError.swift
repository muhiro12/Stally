/// Validation error thrown when backup analysis contains blocking issues.
public struct StallyBackupImportValidationError: Error, Equatable, Sendable {
    /// Blocking issues discovered during analysis.
    public let issues: [StallyBackupImportIssue]

    /// Creates a validation error.
    public init(
        issues: [StallyBackupImportIssue]
    ) {
        self.issues = issues
    }
}
