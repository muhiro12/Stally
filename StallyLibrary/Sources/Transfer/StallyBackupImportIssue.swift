import Foundation

/// One validation issue discovered while previewing a backup import.
public struct StallyBackupImportIssue: Equatable, Sendable, Identifiable {
    /// Severity level for one issue.
    public enum Severity: String, Equatable, Sendable {
        /// Non-blocking issue that should still be surfaced.
        case warning

        /// Blocking issue that prevents import.
        case error
    }

    /// Stable issue code for UI grouping and tests.
    public enum Code: String, Equatable, Sendable {
        /// Snapshot schema version is unsupported.
        case unsupportedSchemaVersion

        /// Snapshot contains duplicate item identifiers.
        case duplicateItemID

        /// Snapshot contains duplicate mark identifiers.
        case duplicateMarkID

        /// Snapshot contains a category no longer recognized locally.
        case unknownCategory
    }

    /// Severity of the issue.
    public let severity: Severity

    /// Machine-readable issue code.
    public let code: Code

    /// Related item identifier when applicable.
    public let itemID: UUID?

    /// Related mark identifier when applicable.
    public let markID: UUID?

    /// Related category raw value when applicable.
    public let categoryRawValue: String?

    /// Human-readable issue message.
    public let message: String

    /// Stable identifier for diffable presentation.
    public var id: String {
        [
            severity.rawValue,
            code.rawValue,
            itemID?.uuidString ?? "-",
            markID?.uuidString ?? "-",
            categoryRawValue ?? "-"
        ].joined(separator: "|")
    }

    /// Creates a backup import issue.
    public init(
        severity: Severity,
        code: Code,
        message: String,
        itemID: UUID? = nil,
        markID: UUID? = nil,
        categoryRawValue: String? = nil
    ) {
        self.severity = severity
        self.code = code
        self.itemID = itemID
        self.markID = markID
        self.categoryRawValue = categoryRawValue
        self.message = message
    }
}
